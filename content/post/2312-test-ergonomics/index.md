---
title: Test Ergonomics
date: 2023-12-11
tags:
  - programming
  - go
  - coin
---

I've had this topic in the back of my mind for a while and recent [talk by Russ Cox](https://research.swtch.com/testing) brought it back to the foreground. As with any of Russ' writing it is well worth your while, I highly recommend you check it out. Of course he makes most of the points I wanted to make and then some, so my remarks will be mostly just reactions to his talk.

What got me thinking about this topic is another example of what he calls "script-based tests". I ran across it studying [ledger-cli](https://ledger-cli.org). The [test directive](https://ledger-cli.org/doc/ledger3.html#Writing-Tests) is genius in its simplicity and pure ergonomics. A test is a simple text file consisting of

* the sample ledger,
* the tested command to execute against it and
* the expected output.

The tested command and output is implemented as just another ledger item type (test), so you can use the same ledger parser to parse the test files as well. The ledger-cli `test` command simply executes the test items and compares the output reporting the success/fail results. Needles to say this was one of the first things I implemented [in coin](https://github.com/mkobetic/coin/blob/master/tests/cmd/reg/basic.test), here's a short `balance` test for illustration:

```
commodity CAD
  format 1.00 CAD

account Assets:Bank
account Income:Salary
account Expenses:Food
account Expenses:Rent

2000/01/01 ACME
  Assets:Bank 1000 CAD
  Income:Salary

2000/01/02 Loeb
  Expenses:Food 20 CAD
  Assets:Bank

2000/01/03 
  Expenses:Rent 500 CAD
  Assets:Bank

test balance Expenses
    0.00 |   520.00 CAD | Expenses
   20.00 |    20.00 CAD | Expenses:Food
  500.00 |   500.00 CAD | Expenses:Rent
end test

test balance -b 2000/01/02
   0.00 | -520.00 CAD | Assets
-520.00 | -520.00 CAD | Assets:Bank
   0.00 |  520.00 CAD | Expenses
  20.00 |   20.00 CAD | Expenses:Food
 500.00 |  500.00 CAD | Expenses:Rent
end test
```

This may seem somewhat trivial in terms of the implementation aspects, but I think its power stems exactly from that simplicity and is amplified by the minimalism and ease of writing these tests. Any competent user of the tool can write a test, no need to be a programmer. I find that brilliant.

I absolutely agree with Russ that ergonomics and quality of the test suite is paramount. What I mean by ergonomics is 

1. The tests are easy to read and write, brevity is a big part of this. If most of the test is long lines of boilerplate code, that's not readable even if it spells things out very clearly. It wastes too much mental energy.

2. The tests (or at least some reasonably representative subset of the suite) are easy and quick to run while working on the code. You need quick feedback loop to make changes or write new code. It's fine for the full suite to take a bit more time in the CI pipeline, but it's not an unlimited time budget there either. You need to be able to be done with a pull request and move on in reasonable time. If you have to start multitasking because you have to wait a lot for things to happen, the results are going to be suboptimal.

3. The test suite is well designed and factored. If every tiny change to the code breaks dozens of test cases then there is too much redundancy in the test suite. Granted some changes will have sweeping fallout, but it cannot be the case with most changes.

I guess all this applies to ergonomics of code in general, so it just reinforces that the test code is as important as the rest of the project. It should be thorough yet minimal, it should be DRY and highly readable, it should be just as maintainable as the rest of the code. Sloppy and bloated test suite makes sloppy and bloated software.