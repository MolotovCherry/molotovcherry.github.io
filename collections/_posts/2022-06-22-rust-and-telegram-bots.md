---
title: Rust and Telegram Bots
author: Cherryleafroad
layout: post
category: Programming
tags: telegram bot rust teloxide tokio
---

Recently I've been having a fun time trying my hand out with telegram and their bot api. I found a wonderful telegram bot library for Rust called [teloxide](https://github.com/teloxide/teloxide).

Since I can't seem to find any good ways to get notified about which anime or manga are on my currently reading lists, I decided to make a bot that will notify me when new shows/chapters come out. This was quite the fascinating adventure!

<!--more-->

## Tokio and Dptree

I started with the wonderful library known as [Tokio](https://github.com/tokio-rs/tokio), since using async is a great way to make the program more responsive when dealing with things like blocking io. Plus, tokio is useful since it handles putting things on new threads for you.

So, I started out with the typical main function that we all start with
```rust
#[tokio::main]
async fn main() {

}
```

Seeing that teloxide is quite a handful to learn at first, it took a little bit to figure out, but anyhow, next we start with the actual dispatcher of course.
```rust
#[tokio::main]
async fn main() {
    Dispatcher::builder(bot, handler())
        .dependencies(dptree::deps![InMemStorage::<State>::new()])
        .build()
        .setup_ctrlc_handler()
        .dispatch().await;
}
```
I played around with the handler function a bit, because I wanted a handler that can handle [dialog](https://github.com/teloxide/teloxide/blob/master/examples/dialogue.rs) as well as regular messages. Since teloxide uses [dptree](https://github.com/teloxide/dptree) which makes use of the [chain (tree) of responsibility](https://en.wikipedia.org/wiki/Chain-of-responsibility_pattern) pattern, it is sometimes a bit difficult to wrap your head around the first time.

I ended up with this handler function.
```rust
fn handler() -> Handler<'static, DependencyMap, Result<(), Box<dyn Error + Send + Sync>>, DpHandlerDescription> {
    dialogue::enter::<Update, InMemStorage<State>, State, _>()
        // handle dialogs + commands
        .branch(dialog::schema())
        // handle remaining messages
        .branch(
            Update::filter_message()
                .branch(
                dptree::filter_async(
                        |_bot: Arc<AutoSend<Bot>>, _msg: Message| {
                            async move {
                                // don't handle any messages for now
                                false
                            }
                        }
                    ).endpoint(|_bot: Arc<AutoSend<Bot>>, _msg: Message| {
                        async {
                            Ok(())
                        }
                    })
                )
                .branch(dptree::endpoint(dialog::invalid_state))
        )
}
```
So, seems cryptic right? Well, it probably is if you haven't encountered it before at least. To put it in the way I understand it, dptree allows you to start with a beginning for processing `dptree::entry()`, and you can supply it with some kind of object to process, then you can add dependencies onto in the chain (dependency injection), and have additional self contained "units" of logic execution. `.branch` is similar to `.chain`, except that it receives the input from the last one. Anyways, I can't say I still fully understand it myself yet, but I understand it enough to get what I need done.

In the example above, we pass the inputs into our dialog handler for processing, but then we also pass it to another branch which filters out the messages, chooses whether to handle them or not, and if not, lets execution continue to the last branch state, which we can make something like the bot sending `Sorry, I didn't catch waht you said`. Quite a useful pattern for bot messaging honestly.

## MyAnimeList API

Anyhow, after making a nice dialog system according to the [teloxide example](https://github.com/teloxide/teloxide/blob/master/examples/dialogue.rs), I needed to interact with the [MAL api](https://myanimelist.net/apiconfig/references/api/v2). I didn't find any real suitable Rust libraries for interacting with MAL, so I made my own from scratch using [serde](https://serde.rs/), [reqwest](https://github.com/seanmonstar/reqwest), and [oauth2](https://github.com/ramosbugs/oauth2-rs). Anyone who has used serde knows it's not that difficult to use. Just provide some structs matching the api, for example:
```rust
#[derive(Deserialize, Serialize, Debug, IntoStaticStr, EnumString, Display, PartialEq, Clone)]
#[serde(rename_all = "snake_case")]
#[strum(serialize_all = "snake_case")]
pub enum WatchStatus {
    Watching,
    Completed,
    OnHold,
    Dropped,
    PlanToWatch
}
```
... pretty easy stuff. Just match up the names the api returns json with. Since the api returns names in `snake_case`, I used serde's `#[serde(rename_all = "snake_case")]` feature to keep the Rust PascalCase convention, while serializing to and deserializing from snake_case. Strum is there simply so we can work with the type easily in Rust.

When dealing with the [MAL api's oauth authentication](https://myanimelist.net/apiconfig/references/authorization), you have to be _very careful_ to do it properly, because it turns out that `code_challenge = code_verification`, which are typically not the same in oauth. If you don't use the same challenge for both, you **will fail** authentication to the system.
```rust
self.client
    // authorization code is the `code` you receive from the api callback in MAL
    .exchange_code(AuthorizationCode::new(code))
    // NOTE: MAL is using the code challenge's code as the code instead of verifier generated one
    // this is in fact the same one we used earlier when generating the oauth url
    .set_pkce_verifier(PkceCodeVerifier::new(challenge_code))
    .request(http_client)?;
```
The api will then return to us an `access_token` and a `refresh_token`. Despite the MAL api saying the code is valid for 30 days, the access token is in fact valid for only one hour. However, the refresh token is valid for 30 days, so you can use that to keep asking for a new authorization token. If you do this before 30 days is up, you can hold onto the authorization indefinitely without having to ask the user to give authorization again. (See the [oauth examples](https://github.com/ramosbugs/oauth2-rs/tree/main/examples) for more information on how to use their library).

Other than that, it's as simple as using the standard way to call the [myanimelist api](https://myanimelist.net/apiconfig/references/api/v2). Provide your `acess_token` in the header just as the spec says, like so, `Authorization: Bearer {access_token}`.

## Receiving the Callback from MAL
The astute reader might have noticed that I haven't even mentioned how to receive the callback from MAL's oauth. You see, you actually need a server URL for that. You can theoretically use your own home IP, forward your ports, run a web-server on it, but it's honestly more pain than it's worth, especially cause IP's are dynamic. You _could_ use a service like no-ip, but I digress.

So, how to do it? Well, I ended up going with Heroku, since they offer a nice free plan with like 550 free hours/month. Yes, the server shuts down after 30 minutes of inactivity, but this doesn't matter much for our use-case. They have a stable URL, IP, you can use nearly ANY programming language you want on their server, AND you can deploy straight from GitHub (I'm not sponsored, I just love that they're offering it for free).

So, I ended up writing a Rust server using [actix](https://github.com/actix/actix) and [actix-web](https://github.com/actix/actix-web). By using the super nice [Rust buildpack](https://github.com/emk/heroku-buildpack-rust) for Heroku, we can deploy an actual Rust server binary very easily (just set the URL to the buildpack in the heroku control panel), and as mentioned before, you can set up automatic deployment every time you push to GitHub.

You can follow the [actix-web](https://github.com/actix/actix-web/blob/master/actix-web/examples/basic.rs) examples for how to use their library, but there is one thing I must address. That is, _our binary WON'T START on heroku._ Why is that? First of all, you must understand two things: 1, heroku provides a specific port you must connect to, and this always changes. Easy enough, just read the `PORT` env var, and if not there, then use a default (for example, when testing the server locally). But 2, we most likely used `127.0.0.1` as the IP; seems reasonable, right? But it won't work. Turns out the solution is to bind to `0.0.0.0`. From my understanding, this allows the IP to be set to whatever it needs to be set to (not sure how it works, but it does).

```rust
#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // heroku uses PORT to tell server what port to start on
    let port = env::var("PORT")
        .unwrap_or_else(|_| "8080".to_string())
        .parse::<u16>()
        .expect("PORT must be a number");

    HttpServer::new(|| {
        App::new()
            .service(callback)
            .service(websocket_client)
            .default_service(web::to(not_found))
    })
        // 0.0.0.0 is require to work on heroku
        .bind(("0.0.0.0", port))?
        .run()
        .await
}
```

## Using the server
Receiving the callback from MAL is easy enough. They provide 2 parameters according to oauth spec, which is `state` and `code`. Just receive these and you're good to go.
```rust
#[derive(Deserialize, Debug, Clone)]
struct MalCallback {
    pub code: String,
    pub state: String,
}

#[get("/callback")]
async fn callback(callback: web::Query<MalCallback>) -> impl Responder {
    // do stuff
}
```
... But what do we do with it? If you ever played with telegram bots, you'll have realized that your bot still runs locally. How will you get the code then?

For this, I used the built-in actix-web-actors, which has websocket support. Some examples for it are [here](https://github.com/actix/examples/tree/master/websockets).

We can make a websocket server on a url like `/client`, but make sure you authenticate the client with a jwt or something, since you should be the only one that receives the private callback information (though technically speaking, no one else still knows the code challenge you provided, so they'd still fail if they tried to use it). Because websockets has no custom headers, we can't do something easily like pass an `Authorization` header. We have to implement our own protocol which asks for authorization, and have the client send it. If not, then disconnect the client since they're not valid. Make sure you're sending heartbeats to keep the client alive. Since this is a heroku service that only has so many hours, I decided to disconnect the client once it is done receiving the information, but you will want to make sure that the server saves and sends the info back to the client EVEN IF the client is not connected.. After all, you want to make sure it is robust. 

Once I got that running, I turned to the [tokio-tungstenite](https://github.com/snapview/tokio-tungstenite/) library for the client. Same thing, just follow your protocol and provide the authorization.

## Getting the Aired episode information
Turns out that MAL doesn't have this info. However, Anilist does! Anilist apparently uses GraphQL instead. Their api docs are [here](https://anilist.gitbook.io/anilist-apiv2-docs/), but they have a wonderful [interactive GraphQL editor](https://anilist.co/graphiql). Thanks to anilist, they allow you to input  MAL ID to correlate it with the ID's you get back from MAL. Perfect!

We can use a GraphQL query like this to get the latest airing episode info for a particular MAL ID. Using the data from this, you can correlate it with your current list and figure out when the next episode airs! Easy peasy!
```graphql
query ($type: MediaType) {
  Media (idMal: <YourID>, type: $type) {
    idMal
    episodes
    nextAiringEpisode {
      episode
      airingAt
    }
  }
}
```

## Conclusion
That's actually pretty much it. The principle isn't too difficult, if not more time consuming. But we made it! I apologize for big lack of code in this post, but my source code for the bot is private. Hope this post helps somebody though. :) If you have any questions, feel free to ask in the comments.
