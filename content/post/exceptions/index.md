---
title: Exceptions vs errors
draft: true
---

Go standard lib stats on `if err != nil { return err }`

https://en.wikipedia.org/wiki/Greenspun%27s_tenth_rule

exceptions can be a mess, errors force you to handle them

exceptions should be exceptional
https://dave.cheney.net/2015/01/26/errors-and-exceptions-redux
https://dave.cheney.net/2016/04/27/dont-just-check-errors-handle-them-gracefully
https://www.hacklewayne.com/golang-error-handling-yes-to-values-no-to-exceptions-a-win-for-the-future

exception performance