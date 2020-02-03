# ExBanking
ExBanking is an application that can keep track of money of different currencies for various users.

This is an example of the supervision tree for an app running with 4 accounts (Anna, Aron, John and Marina).
![Supervision Tree](docs/img/supervision_tree_preview.png?raw=true)

**The code documentation can be found [here](https://victor-am.github.io/ex_banking/ExBanking.html)**

## Modules
### [ExBanking](https://github.com/victor-am/ex_banking/blob/master/lib/ex_banking.ex)
The ExBanking module serves as the entrypoint for the application and the module responsible for presentation issues (like converting money between different formats), and it's APIs are the only things meant to be directly exposed to the outside world.

It's a very thin layer of the application, apart from input validation and some data transformation it mostly just calls Account module methods to perform the actual operations.

### [Account](https://github.com/victor-am/ex_banking/blob/master/lib/ex_banking/account.ex)
The Account module is responsible for handling interactions between the ExBanking functions and the GenServer implemented in AccountServer. It handles some business logic while also translating the low-level messages from AccountServer to business messages that ExBanking can actually return.

### [AccountServer](https://github.com/victor-am/ex_banking/blob/master/lib/ex_banking/account_server.ex)
The AccountServer module is a GenServer that is responsible for one user account at a time (multiple of them are spawned under the AccountsSupervisor). It handles most of the concurrency-dependent code and is in a considerably lower-level than the Account module for example.

### [Money](https://github.com/victor-am/ex_banking/blob/master/lib/ex_banking/money.ex)
The functions inside this module are used to convert money between integer and 2 decimal places float formats. More information can be found about this can be found [here](https://github.com/victor-am/ex_banking#handling-money).

## Design choices
There is some reasoning about the choices I've made both in the commit messages and in the code documentation, but I think it's worth to delve a bit more into the most interesting ones:

### One account per process
One account per process allow us to isolate fails between accounts, so if something happen to a customer, the rest should be safe. The only touchpoint between accounts is the `send` operation, that was implemented taking into consideration some failure possiblities and a rollback strategy in case anything goes wrong.

### Handling money
Since I wasn't sure if just using Integers with the last two digits counting as decimals would be enough to satisfy the app requirements of money with 2 decimal places, I've made money handling module (called... you guessed it! `Money`) that takes care of float/integer conversion.

The app works on the premise that if money is inputed as a float the decimal places are the cents, otherwise it asumes there are no cents. Ex:

```
100    = 100.00
100.10 = 100.10
```

Internally though, the app converts the input to integer (multiplying by 100 to keep the decimal places) as it's a far safer format for money than float. Then on the output the app converts the integer back into a float to keep consistency.

### The 10 operation queue limit ([1c178b](https://github.com/victor-am/ex_banking/commit/1c178b1fd52ac876c95e7193b41eb2f6a13bf2eb))
The limit was implemented in a most simplistic way (using Process.info which isn't very well meant for production code). The other option I considered would be to handle the queue manually through code, but this would raise a lot the complexity of the code for not that much gain.

In a real life scenario though, I would prefer a deadline mechanism (timeout messages in the queue based on time elapsed) to a message count one. I think limiting the queue through time could prove more flexible as it could better accomodate functions with very different execution times.
