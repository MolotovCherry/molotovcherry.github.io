---
title: Killing Annoying Processes in Windows
author: Cherryleafroad
layout: post
categories:
  - Programming
tags: rust
---

Mainly 2 things have been annoying me lately while working on my computer. These being, 2 incessant processes that won't stop running and eating 90% of the CPU.

Yes, I'm looking at you `CompatTelRunner.exe` and `Software_Reporter_Tool.exe`.

<!--more-->

Normally such things wouldn't be much of a worry as they're not often, but these two specifically seem to run whenever they want without any regard to the users machine.

I've tried various fixes over the months, ranging from [blocking it](https://www.technipages.com/prevent-users-from-running-certain-programs) using the registry/group policy, [disabling](https://windowsreport.com/compattelrunner-exe-file-issues/) the running tasks in task scheduler, [fiddling](https://docs.microsoft.com/en-us/microsoft-desktop-optimization-pack/appv-v4/how-to-deny-access-to-an-application) with file permissions to deny access to the executable, and [disabling](https://wethegeek.com/how-to-disable-telemetry-and-data-collection-in-windows-10/) as much telemetry as possible, even [Winaero Tweaker](https://winaero.com/winaero-tweaker-0-6-0-2-is-out-allows-to-disable-telemetry-in-windows-10-and-more/)'s disable telemetry feature.

Really, none of these worked at all! I've begun to think these are a serious virus (might as well be with how annoying it was). No matter what I do, `CompatTelRunner.exe` runs every time a program installs or uninstalls. 

So, I decided to finally turn to Rust to solve my problem, by making something that watches processes and kills them right away. A Process Killer!

I decided to turn to the [sys-info](https://crates.io/crates/sysinfo) crate, considering its ease of use for scanning processes and PID's. After writing a quick loop to scan every x seconds, and kill the process, all good! .. That is, until I hit a snag. It seems that system processes can't be killed, even if you're running as admin, unless you use [SeDebugPrivilege](https://docs.microsoft.com/en-us/windows/win32/secauthz/enabling-and-disabling-privileges-in-c--). Came with a nice snippet of C++ too.

So I turned to [windows-rs](https://github.com/microsoft/windows-rs) crate to translate it over since I couldn't find a crate for this. After a little bit, I came up with this unsafe code to grant any privilege to a process in Rust.

```rust
pub fn set_privilege(name: &str, state: bool) -> Result<(), Box<dyn Error>> {
    unsafe {
        let handle = OpenProcess(PROCESS_QUERY_INFORMATION, false, std::process::id());
        if handle.is_invalid() {
            return Err(Box::new(ProcessError::NullHandle));
        }

        let mut token_handle = HANDLE(0);
        let res: bool = OpenProcessToken(
            handle,
            TOKEN_ADJUST_PRIVILEGES,
            &mut token_handle as *mut _
        ).into();

        if !res {
            return Err(Box::new(ProcessError::OpenProcessTokenFailed));
        }

        let mut luid = LUID::default();
        let privilege = CString::new(name)?;
        let res: bool = LookupPrivilegeValueA(
            PCSTR::default(),
            PCSTR(privilege.as_ptr() as *const _),
            &mut luid as *mut _
        ).into();

        if !res {
            return Err(Box::new(ProcessError::PrivilegeLookupFailed));
        }

        let mut tp = TOKEN_PRIVILEGES::default();
        tp.PrivilegeCount = 1;
        tp.Privileges[0].Luid = luid;

        if state {
            tp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;
        } else {
            tp.Privileges[0].Attributes = TOKEN_PRIVILEGES_ATTRIBUTES(0u32);
        }

        let res: bool = AdjustTokenPrivileges(
            token_handle,
            false,
            &tp as *const _,
            std::mem::size_of::<TOKEN_PRIVILEGES>() as u32,
            std::ptr::null_mut() as *mut _,
            std::ptr::null_mut() as *mut _
        ).into();

        if !res {
            return Err(Box::new(ProcessError::AdjustTokenPrivilegeFailed));
        }

        let res: bool = CloseHandle(handle).into();
        if !res {
            return Err(Box::new(ProcessError::CloseHandleFailed));
        }

        let res: bool = CloseHandle(token_handle).into();
        if !res {
            return Err(Box::new(ProcessError::CloseHandleFailed));
        }
    }

    Ok(())
}
```

Works great! So far so good! By using `set_privilege(SE_DEBUG_NAME, true);` in the main program we can grant ourselves the `SE_DEBUG_NAME` privilege when we run as admin, and now system processes can be killed!

Of course, I also needed some process killer code, and no better than to turn to the MS API!

```rust
pub fn kill_process(pid: u32) -> Result<(), ProcessError> {
    unsafe {
        let handle = OpenProcess(PROCESS_TERMINATE, false, pid);
        if handle.is_invalid() {
            return Err(ProcessError::NullHandle);
        }

        let res: bool = TerminateProcess(handle, 0).into();
        if !res {
            return Err(ProcessError::TerminationFailed);
        }

        let res: bool = CloseHandle(handle).into();
        if !res {
            return Err(ProcessError::CloseHandleFailed);
        }
    }

    Ok(())
}
```

Great! Now I can scan for processes, and kill them even if they're a system process! But one thing kept bothering me. It seemed so inefficient to keep scanning for processes every x seconds. I need a better solution.

After a bit of researching, I found that WMI can do this with a query such as  
`SELECT * FROM __InstanceCreationEvent WITHIN 2 WHERE TargetInstance ISA 'Win32_Process'`  
but this requires `IWbemServices::ExecNotificationQueryAsync` which is not implemented in the Rust WMI crate. Sad.

I came across [this](https://docs.microsoft.com/en-us/windows/win32/wmisdk/example--receiving-event-notifications-through-wmi-) Microsoft SDK code example to receive async event notifications from WMI. Looks like that's what I need. The Rust Windows API seemed clunky at best however, and I got stuck as I needed to make a custom COM interface which implemented [IWbemObjectSink](https://docs.microsoft.com/en-us/windows/win32/wmisdk/iwbemobjectsink), and there wasn't really any way to do it with windows-rs. So I turned to [com-rs](https://github.com/microsoft/com-rs) which seemed to solve this, but unfortunately this is mostly for [winapi](https://crates.io/crates/winapi), and I didn't want to use winapi compared to the official Microsoft bindings.

I ended up [making an issue report](https://github.com/microsoft/com-rs/issues/237) in the `com-rs` repo, and thankfully, Kenny - the MS employee working on windows-rs - was already planning to work on the COM interface in windows-rs. I just needed to wait a little longer. So I waited about a week or 2, and sure enough, a bunch of PR's got pulled in and we got a new release!

So, using wmi-rs's [COM implementation](https://github.com/ohadravid/wmi-rs/blob/main/src/query_sink.rs) as a basis, I reworked it into a windows-rs compatible COM interface.

```rust
// This is IWbemObjectSink
// must be declared as pub: https://github.com/microsoft/windows-rs/pull/1611
#[interface("7C857801-7381-11CF-884D-00AA004B2E24")]
pub unsafe trait IEventSink: IUnknown {
    unsafe fn Indicate(
        &self,
        lObjectCount: c_long,
        apObjArray: *mut *mut IWbemClassObject
    ) -> HRESULT;

    unsafe fn SetStatus(
        &self,
        lFlags: c_long,
        _hResult: HRESULT,
        _strParam: BSTR,
        _pObjParam: *mut IWbemClassObject
    ) -> HRESULT;
}

#[implement(IEventSink)]
pub struct EventSink {
    pub sender: Sender<Result<IWbemClassObjectWrapper, WMIError>>
}

impl EventSink {
    pub fn new(sender: Sender<Result<IWbemClassObjectWrapper, WMIError>>) -> Self {
        Self {
            sender
        }
    }
}

/// Implementation for [IWbemObjectSink](https://docs.microsoft.com/en-us/windows/win32/api/wbemcli/nn-wbemcli-iwbemobjectsink).
/// This [Sink](https://en.wikipedia.org/wiki/Sink_(computing))
/// receives asynchronously the result of the query, through Indicate calls.
/// When finished,the SetStatus method is called.
/// # <https://docs.microsoft.com/fr-fr/windows/win32/wmisdk/example--getting-wmi-data-from-the-local-computer-asynchronously>
impl IEventSink_Impl for EventSink {
    unsafe fn Indicate(
        &self,
        lObjectCount: c_long,
        apObjArray: *mut *mut IWbemClassObject
    ) -> HRESULT {
        debug!("entered indicate");
        debug!("Indicate call with {lObjectCount} objects");
        // Case of an incorrect or too restrictive query
        if lObjectCount <= 0 {
            return HRESULT(WBEM_S_NO_ERROR.0);
        }

        let lObjectCount = lObjectCount as usize;

        // The array memory of apObjArray is read-only
        // and is owned by the caller of the Indicate method.
        // IWbemClassWrapper::clone calls AddRef on each element
        // of apObjArray to make sure that they are not released,
        // according to COM rules.
        // https://docs.microsoft.com/en-us/windows/win32/api/wbemcli/nf-wbemcli-iwbemobjectsink-indicate
        // For error codes, see https://docs.microsoft.com/en-us/windows/win32/learnwin32/error-handling-in-com

        let slice = std::slice::from_raw_parts(
            apObjArray,
            lObjectCount
        );

        for obj in slice {
            let obj: &IWbemClassObject = core::mem::transmute(obj);

            let newobj = IWbemClassObjectWrapper::new(obj.Clone().unwrap());
            if let Err(e) = self.sender.try_send(Ok(newobj)) {
                warn!("Failed to send IWbemClassObject through channel: {:?}", e);
                return E_POINTER;
            }
        }

        HRESULT(WBEM_S_NO_ERROR.0)
    }

    unsafe fn SetStatus(
        &self,
        lFlags: c_long,
        _hResult: HRESULT,
        _strParam: BSTR,
        _pObjParam: *mut IWbemClassObject
    ) -> HRESULT {
        // SetStatus is called only once as flag=WBEM_FLAG_BIDIRECTIONAL in ExecQueryAsync
        // https://docs.microsoft.com/en-us/windows/win32/api/wbemcli/nf-wbemcli-iwbemobjectsink-setstatus
        // If you do not specify WBEM_FLAG_SEND_STATUS when calling your provider or service method,
        // you are guaranteed to receive one and only one call to SetStatus
        if lFlags == WBEM_STATUS_COMPLETE.0 {
            debug!("End of async result, closing transmitter");
            self.sender.close();
        }
        HRESULT(WBEM_S_NO_ERROR.0)
    }
}
```

Took a bit to figure out the unsafe code that windows was expecting, especially the `*mut *mut`, but after a bit in the Rust discord, it's all good now! Now I was able to make a WMI connection AND receive async `IWbemClassObject`'s from WMI! But trouble soon popped up again as I wasn't sure how to access a `Win32_Process` instance. After using the built-in `wbemtest` windows program, I soon discovered that `TargetInstance` was returned by the WMI query and was in fact a `Win32_Process` instance!

But after messing a bit with [SAFEARRAY](https://docs.microsoft.com/en-us/archive/msdn-magazine/2017/march/introducing-the-safearray-data-structure) and [VARIANT](https://docs.microsoft.com/en-us/windows/win32/api/oaidl/ns-oaidl-variant), it seemed very difficult to extract the raw instance data. But I finally found hope after Googling a lot, and what needed to happen was it needs to be cast to an `IUnknown` interface, after which it can be casted back to `IWbemClassObject`

```rust
pub fn get_embedded_object(&self, name: &str) -> Result<IWbemClassObjectWrapper, Box<dyn Error>> {
    let mut variant = VARIANT::default();
    let property = BSTR::from(name);
    let property = property.as_wide();
    let mut cim_type = 0i32;

    let processObject = unsafe {
        self.obj.Get(
            PCWSTR(property.as_ptr()),
            0,
            &mut variant as *mut _,
            &mut cim_type as *mut _,
            std::ptr::null_mut()
        )?;

        if cim_type != CIM_OBJECT.0 {
            return Err(Box::new(WMIError::NotCimObject))
        }

        // convert embedded object to IUnknown, then cast to IWbemClassObject
        let pVal = variant.Anonymous.Anonymous.Anonymous.punkVal.as_ref().unwrap();
        let processObject = pVal.cast::<IWbemClassObject>()?;

        Self::new(processObject)
    };

    Ok(processObject)
}
```

It works! Great!! Now I have an instance of `Win32_Process`. Of course, for every property that the WMI query returns we need to access the data contained.

So first we get all the property names
```rust
let mut arrs = VecDeque::new();

unsafe {
    let _safearray = self.obj.GetNames(
        PCWSTR::default(),
        WBEM_FLAG_ALWAYS.0,// | WBEM_FLAG_NONSYSTEM_ONLY.0,
        &VARIANT::default() as *const _ as *const _
    )?;

    let mut ptr: *mut c_void = std::mem::zeroed();

    SafeArrayAccessData(
        _safearray as *const _,
        &mut ptr as *mut _
    )?;

    let safearray = *_safearray;

    for i in 0..safearray.cDims as usize {
        let slice = std::slice::from_raw_parts(
            ptr as *mut BSTR,
            safearray.rgsabound[i].cElements as usize
        );
        arrs.push_back(slice.into_iter().map(|f| f.to_string()).collect::<Vec<String>>());
    }

    SafeArrayUnaccessData(
        _safearray
    )?;
}
```
Then we can get the `VARIANT` after knowing the property names, and handle every single type of property by checking what data the `VARIANT` union holds at `variant.Anonymous.Anonymous.vt` using this [nice list](https://docs.microsoft.com/en-us/windows/win32/api/wtypes/ne-wtypes-varenum) of types from Microsoft SDK.
```rust
let mut variant = VARIANT::default();
let property = BSTR::from(name);
let property = property.as_wide();
let mut var_type = 0i32;

unsafe {
    self.obj.Get(
        PCWSTR(property.as_ptr()),
        0,
        &mut variant as *mut _,
        &mut var_type as *mut _,
        std::ptr::null_mut()
    )?;

    match VARENUM(variant.Anonymous.Anonymous.vt as i32) {
        VT_UNKNOWN => {
            // this unknown type is generally an embedded object
            if var_type != CIM_OBJECT.0 {
                return Err(Box::new(WMIError::NotCimObject))
            }

            // convert embedded object to IUnknown, then cast to IWbemClassObject
            let pVal = variant.Anonymous.Anonymous.Anonymous.punkVal.as_ref().unwrap();
            let embeddedObject = pVal.cast::<IWbemClassObject>()?;
            ValueType::CIM_OBJECT(Self::new(embeddedObject))
        }

        VT_BSTR => {
            let bstring = &*variant.Anonymous.Anonymous.Anonymous.bstrVal;
            let string = bstring.to_string();
            ValueType::BSTR(string)
        }

        // float 32
        VT_R4 => {
            ValueType::R4(variant.Anonymous.Anonymous.Anonymous.fltVal)
        }
    
        // etc
    }
}
```
After parsing all this into an enum, we have safely parsed all the typed data from the union and know what data all the properties hold! Sweet!

In the end I ended up using [tokio](https://crates.io/crates/tokio) so I could get some nice async with a [ctrl+c handler](https://crates.io/crates/ctrlc), and I ended up with this beauty!

```rust
loop {
    select! {
        // ctrl c break
        _ = rx.recv() => break,

        Ok(Ok(process)) = rx2.recv() => {
            let inst = process.get_embedded_object("TargetInstance")?;

            let res = Win32_Process::from(inst);
            println!("Started {}, {}", res.Name, res.ProcessId);
            if data.processes.contains(&res.Name.to_lowercase()) {
                println!("{} is disallowed! Killed!", res.Name);
                utils::kill_process(&res.Name, res.ProcessId as u32)?;
            } else {
                println!("{} is allowed", res.Name);
            }
            println!();
        }
    }
}
```

And now, I never need to check for processes again, since Windows itself will notify my process when a new one starts, otherwise we'll just let async let our thread sleep and do no work!

The full code for the project can be found [here](https://github.com/cherryleafroad/AnnoyingProcessKiller/).
