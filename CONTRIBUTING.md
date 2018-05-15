# How to Help

**First:** If you're unsure or afraid of *anything*, just ask or submit the issue or pull request anyways. You won't be yelled at for giving your best effort. The worst that can happen is that you'll be politely asked to change something. I'm still really new at this whole open source thing. So we can learn together.

## Submit Issues

I'm the first to admit that I don't test nearly as much as I should. If you run into bugs, weirdness, or something just doesn't make sense, submit a new [Issue](https://github.com/rmbolger/Posh-ACME/issues).

### Regarding DNS Plugin Requests

If you want your provider supported but can't write the plugin yourself, submit an issue with the request and I'm happy to give it a try. But the hardest part about writing new DNS plugins so far is getting an account with the provider to test with. Providers with free trials or sandbox/test environments are great. Otherwise, I just need temporary access to an existing account **or** a [donation](https://paypal.me/rmbolger) to cover the cost of setting up a new account with the provider.

## Write Tests

Speaking of testing, this project is one of my first attempts at writing [Pester](https://github.com/pester/Pester) tests for PowerShell (and unit testing in general). Help me get better by adding tests to the project. I'm also open to code refactoring suggestions that will make testing easier.

## Add to the Wiki

Is there some documentation you wish you had when you were first playing with the module? Did I make a spelling mistake? Does my grammar suck?

## Features and Functionality

I know there are loads of use cases I haven't considered. If you have an idea for a new feature or functionality change, submit an issue first so we can discuss it. I'd hate for you to waste time implementing a feature that I may never pull into the project.

## Code Guidelines

I'm trying to keep this module as close to pure PowerShell as possible. Definitely avoid binary dependencies. Try to avoid blocks of C# code loaded via `Add-Type`. Favor programmatic solutions over calling external executables when possible.

I'm not super strict about code formatting as long as it seems readable. I'm a bit OCD about removing white space at the end of lines in my own commits though. Just don't make huge commits that contain a bunch of whitespace or formatting changes.

## Say Hi and Tell Your Friends

There's nothing that makes me want to work on this project more than knowing people use it other than myself. Drop me a line on Twitter ([@rmbolger](https://twitter.com/rmbolger)) and tell your friends about it.
