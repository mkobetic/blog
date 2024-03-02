+++
title = 'Freelancing'
draft = true
+++

What I really want to write about is how I'm using plaintext accounting to track everything about my freelancing business. But I realize that before I describe my little scheme, first I need to say a few things about how I operate, for it to make any sense. I concede that it is possible if not likely that most may find the operate part more interesting than the accounting part.

First few words of caution. I've only been doing this for a few months, and while I'm happy with it so far, that's not a terribly long evaluation period. The accounting part is going to be even more questionable. I'll be throwing around accounting terms and concepts reflecting my current (lack of) understanding. It's highly unlikely it will stand up to scrutiny by an actual accountant. You've been warned, now let's get to it.


# Operations

I work remotely, mostly alone and charge by the hour, so it is important that both me and my client understand what I'm doing and that it is what the client wants me to do. The sooner we can identify any discrepancy the easier it is to maintain a pleasant and trusting relationship.

For every task/problem I'm working on there is a written record with the initial problem statement followed by mostly daily updates of where I am with the solution and what are the next steps I intend to take. In programming world this record is usually something like a Github Issue or any of the countless equivalents out there.

The purpose of the update is to convey in broad strokes the progress being made, the solutions being pursued, bringing up unresolved questions or obstacles encountered and what you're going to do about those. Progress doesn't necessarily mean new stuff being added, if you realize that you've been going in the wrong direction, explain why and scrap what is wrong. As someone smart said, failure is a successful discovery of something that doesn't work and it is important to capture it in the record. In the end the record should outline the whole journey to the final solution.

The updates also need to be succinct and to the point, because you need the client to be able to follow your progress as well. You need the client to understand what is going on at all times and be able to jump in and correct course as soon as possible. To keep this communication smooth most updates should require no intervention from the client, just a quick read and understanding.

The updates also help you to get your thoughts together, to summarize the substantive bits and to plot a new course as you discover things. It still surprizes me often how the act of trying to explain something to someone else can be illuminating for both parties. The updates also help you to get back into it quickly if the work is interrupted for any reason (or if it is picked up by somebody else).

Finally, if there's later any discussion about what happened in the course of the task, the record is there to serve as a reference.

For all its value the record is not the intended product. In my case the product is code shipped into production. This usually happens through Github PRs or something similar, but this aspect doesn't have much impact on the accounting part. The important point is that all work can be tracked by the task being worked on and that the accompanying issue is a complete record of what has been done.


# Accounting

If you want to get paid for your work, you need to produce an invoice showing how much time you've spent and what you've spent it on. I'm using plaintext accounting to keep track of that, this is where it gets a bit nerdy.

Most plaintext accounting tools allow you to define arbitrary commodities, and time can be such a commodity as well. With that you can track time spent using a standard accounting transaction. In my scheme I'm accumulating time spent into Assets:Billable account, since the time you've worked becomes an asset of your freelancing business. The time has to come from somewhere, I created Equity:Time account for that. This is likely very liberal interpretation of what Equity means, but I think that's what makes most sense. So my time tracking transaction would looks something like this

```
2024/02/02 ClientX ; #issue-4444: make the thing do that thing
  Assets:Billable   2.5 H
  Equity:Time      -2.5 H
```

I update the time entries regularly through the day as I'm finishing bits and taking breaks. You'd have multiple transactions each day if you work on multiple tasks or for multiple clients.
When the time comes to make an invoice I can ask the tool to give me a running total of all Assets:Billable transactions (filtered by client if needed) since given date and include the notes with issues being worked on. A week's worth of work could look something like this:

```
2024/01/29 | ClientA |  Equity:Time |   1.00 |  1.00 H 
           ; setup
2024/01/29 | ClientA |  Equity:Time |   4.50 |  5.50 H 
           ; #issue-4444: make the thing do that thing
2024/01/30 | ClientA |  Equity:Time |   2.00 |  7.50 H 
           ; #issue-4444: make the thing do that thing
2024/01/30 | ClientA |  Equity:Time |   3.50 | 11.00 H 
           ; #issue-3333: the other thing
2024/01/31 | ClientA |  Equity:Time |   5.00 | 16.00 H 
           ; #issue-4444: make the thing do that thing
2024/02/01 | ClientA |  Equity:Time |   4.00 | 20.00 H 
           ; on-site meeting
2024/02/01 | ClientA |  Equity:Time |   3.00 | 23.00 H 
           ; #issue-4444: make the thing do that thing
2024/02/02 | ClientA |  Equity:Time |   4.00 | 27.00 H 
           ; #issue-4444: make the thing do that thing
```

This gives me the total hours and a list itemized by date and task for the invoice. When I create and send the invoice I also add an invoicing transaction that looks like this:

```
2024/02/03 ClientA ; #INV-ClientA:240203
  Assets:Billable    -27.00 H
  Liabilities:HST    -13.00 CAD
  Assets:Receivable  113.00 CAD
```

The hours that I invoice come out of the Billable account and instead the corresponding amount goes into Receivable account. It is still the same asset just changed its form from hours to dollars. The government requires me to tack on 13% HST tax that I have to include in the invoice, but it becomes my future liability that the government will want me to pay later.
Separating it like this allows keeping track of the time you have worked but haven't billed yet (Billable) and money you invoiced but haven't received yet (Receivable).

When the payment comes into my account, I add another transaction that looks like this:

```
2024/02/05 ClientA ; #INV-ClientA:240203
  Equity:Time          27.00 H
  Income:Consulting  -113.00 CAD
  Assets:Receivable  -113.00 CAD
  Assets:Bank         113.00 CAD
```

The money you receive comes from Income:Consulting account and goes into the Bank account. At the same time it needs to come out of the Receivable account since it was received, to balance that out I return the corresponding hours back to Equity. With this you have your current money on hand in Assets:Bank and the income you've earned so far in Income:Consulting. The balance sheet with the above transactions would look like this:

```
     0.00 |  113.00 CAD | Assets
   113.00 |  113.00 CAD | Assets:Bank
     0.00 |    0.00 H   | Assets:Billable
     0.00 |    0.00 CAD | Assets:Receivable
     0.00 |    0.00 H   | Equity:Time
     0.00 | -113.00 CAD | Income
  -113.00 | -113.00 CAD | Income:Consulting
     0.00 |  -13.00 CAD | Liabilities
   -13.00 |  -13.00 CAD | Liabilities:HST
```

When the taxman comes, money will flow from Assets:Bank to Expenses:Taxes and Liabilities:HST. Of course tracking all the usual accounting stuff is part of the setup as well. My list of accounts looks currently something like this:

```
Assets                       | CAD        | 
Assets:Bank                  | CAD        | 
Assets:Bank:BUS              | CAD        | Business account
Assets:Billable              | H          | Billable time
Assets:Receivable            | CAD        | Time invoiced
Equity                       | CAD        | 
Equity:Time                  | H          | My time
Expenses                     | CAD        | 
Expenses:Cell                | CAD        | Cell phone
Expenses:Internet            | CAD        | Internet fees
Expenses:PD                  | CAD        | Personal development expenses
Expenses:Personal            | CAD        | transfer to personal books
Expenses:Services            | CAD        | 
Expenses:Services:Accounting | CAD        |
Expenses:Services:Legal      | CAD        |
Expenses:Site                | CAD        | domain, hosting, etc
Expenses:Tax                 | CAD        | 
Income                       | CAD        | 
Income:Consulting            | CAD        | 
Liabilities                  | CAD        | 
Liabilities:HST              | CAD        | Invoiced HST
Liabilities:Visa             | CAD        | 
```
