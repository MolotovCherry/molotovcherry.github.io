# Rust JNI Maco

So, during the implementation of [KMagick](https://github.com/cherryleafroad/kmagick/), I came up against a problem: With hundreds of functions all needing to be wrapped in JNI calls, how was I ever going to manage creating so much boilerplate code?

This led to me working hard to research the Rust AST and [syn](https://crates.io/crates/syn) in order to create a fully working macro which autogenerates JNI FFI calls from Rust code without any effort!

It handles idiomatic Rust code perfectly, allowing you to return `Result` types which, if they fail, will throw a native exception in Kotlin (rather than crashing). And, if for any reason the Rust code itself panics, it also will throw an exception in Kotlin rather than crashing the JVM (it achieves this using Rusts [catch_unwind](https://doc.rust-lang.org/std/panic/fn.catch_unwind.html)).

I ended up with an interface like this, for functions
```rust
#[jmethod(cls="some/java/cls", exc="some/exception/ExcCls")]
fn my_java_function(env: JNIEnv, obj: JObject) -> JNIResult<()> {
    env.do_something()?;
    Ok(())
}
```

And it can even handle actual `impl`s AND keep state in-between calls using FFI magic (use a `var handle: Long? = null` on the Kotlin side to store the handle).
```rust
struct Foo {
    state: bool
}

#[jclass(pkg="some/java/pkg", exc="some/exception/Cls")]
impl Foo {
    #[jnew]
    fn new() -> Self {
        Self {
            state: false
        }
    }
    
    fn state_call(&mut self, env: JNIEnv, obj: JObject, new_state: jboolean) -> JNIResult<()> {
        // bubble up error to Kotlin
        some_rust_call(new_state)?;
        
        // as you can see, we have access to the old state in-between calls and can even change it
        self.state = new_state;
        Ok(())
    }
    
    #[jstatic]
    fn static_call(env: JNIEnv, obj: JObject) {
        // we can even make static calls
    }
    
    #[jignore]
    fn pure_rust_fn(&self) {
        // and we can ignore a fn to stop it from being seen by JNI
        self.do_stuff();
    }
    
    #[jname(name="jni_sees_this_name")]
    fn different_name(&self, env: JNIEnv, _: JObject) {
        // or we can change the function name
    }
}
```

All in all, this allowed me to auto generate 1.7mb of JNI binding code while keeping all my Rust idiomatic! Lovely!

(If you're curious what a generated function looks like... It's similar to this)
```rust
#[no_mangle]
pub extern "system" fn Java_com_cherryleafroad_kmagick_Magick_magickQueryFonts(
    env: JNIEnv,
    GCNAyNEouE: JObject,
    pattern: JString,
) -> jobjectArray {
    let p_res = std::panic::catch_unwind(|| {
        let c_res = Magick::magickQueryFonts(env, GCNAyNEouE, pattern);
        match c_res {
            Ok(v) => v,
            Err(e) => {
                let _ = env.throw_new("com/cherryleafroad/kmagick/MagickException", "");
                std::ptr::null_mut()
            }
        }
    });
    match p_res {
        Ok(v) => v,
        Err(e) => {
            let msg;
            let e = e.downcast_ref::<&'static str>();
            if let Some(r) = e {
                msg = "";
            } else {
                msg = "";
            }
            
            let _ = env.throw_new("java/lang/RuntimeException", msg);
            std::ptr::null_mut()
        }
    }
}
```

The macro is actually generalized and can be used by anyone. Check [here](https://github.com/cherryleafroad/kmagick/tree/main/rust) if you'd like to know more.
