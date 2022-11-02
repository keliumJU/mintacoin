<div align="center">
  <h1>Mintacoin</h1>
  <!-- Badges -->
  <a href="https://docs.mintacoin.co">
    <img src="https://img.shields.io/badge/docs-docs.mintacoin.co-blue" alt="Mintacoin Documentation">
  </a>
  <img src="https://img.shields.io/github/workflow/status/kommitters/mintacoin/Mintacoin%20CI/main" alt="Build Status">
  <a href="https://coveralls.io/github/kommitters/mintacoin">
    <img src="https://coveralls.io/repos/github/kommitters/mintacoin/badge.svg" alt="Coverage Status">
  </a>
</div>
<br>

![banner][banner-img]

[**Mintacoin**][www] is a minimalist and open-source API that abstracts the blockchain complexity by providing a simple and reliable infrastructure layer to mint your crypto assets and process payments with them.

Reach the power of blockchain with just an API integration! 🪄

## What can you do with Mintacoin?

Mintacoin will provide endpoints so you can:
- Create accounts.
- Create crypto assets.
- Process payments.

Mintacoin operates on the [Stellar blockchain][stellar], you only have to worry about two custom keys we'll give you: an **address** and a **signature**. 👌

## Motivation

The adoption of Web3 implies technical knowledge specific to each technology, ecosystem, or protocol. This results into:

- High technical complexity.
- Time and effort.
- Slow time to market, therefore high development costs.

Mintacoin aims to solve these current Web3 issues!

## Why Mintacoin?

Web3 needs additional infrastructure layers that facilitate the user experience (UX) in the use of blockchain technologies.

Mintacoin offers a simple and reliable infrastructure layer, so people can focus on their core business and not on the issues previously described. 🚀

## What do we want to achieve?

- Make straightforward the adoption of Web3 technologies for developers by proposing interaction with a REST API rather than a blockchain.

- Reduce technical complexity, costs, and time to the market for solutions around crypto assets.

## Documentation

Mintacoin's documentation is available here: [docs.mintacoin.co](https://docs.mintacoin.co)

## Roadmap

To know the current status of the project, you can check Mintacoin's roadmap here: [**ROADMAP**][roadmap] 🗺️

> The current release for the project is the version **v0.3.1**.

## Development

Here we will show up the Mintacoin's setup for development purposes, follow the next steps:

### Requirements

- Elixir <= v1.14
- Erlang <= 24.3
- PostgreSQL >= v14 (latest)

#### Setting up

1. Install dependencies with `mix deps.get`.

2. Mintacoin requires a development configuration file. Copy the example with the `cp config/dev.exs.example config/dev.exs`.

3. Within the file `dev.exs` replace the following variables:

    - **`"STELLAR_FUND_SECRET_KEY"`**: Is the secret key from a stellar account with funds, you can create and fund one here: [Stellar Laboratory][stellar-laboratory].
    - **`"BLOCKCHAINS_NETWORK"`**: Is the place where the transactions has effect, for development purposes, place this value `:testnet`.
    - **`"API_TOKEN"`**: Is the authorization token for the API requests, you can generate a secure token by running `mix phx.gen.secret 32`.

4. Create and migrate your database with `mix ecto.setup`.

5. Run the project in a terminal with `iex -S mix` and add the next record with `Mintacoin.Blockchains.create(%{name: "stellar", network: "testnet"})`.

6. Finally, start the Phoenix server with `mix phx.server` or inside IEx with `iex -S mix phx.server`.

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

#### Testing

Run the tests with `mix test`.

#### Setting up with Docker

1. First, you need to execute steps **2** and **3** from the previous setup.

2. Build the Phoenix and Postgres images with `docker-compose build`.

3. Finally, run the containers `docker-compose up`.

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser (only if port 4000 is available).

#### Testing with Docker

Run the tests with `docker-compose run mintacoin_api mix test`.

#### Run commands with Docker
* Run the IEx console with `docker-compose run mintacoin_api iex -S mix`. 
* Run your new migrations with `docker-compose run mintacoin_api mix ecto.migrate`. 
* Install new dependencies with `docker-compose run mintacoin_api mix deps.get`. 
* Run any mix task with `docker-compose run mintacoin_api mix <task>`.

---

## Changelog

Features and bug fixes are listed in the [CHANGELOG][changelog] file.

## Code of conduct

We welcome everyone to contribute. Make sure you have read the [CODE_OF_CONDUCT][coc] before.

## Contributing

Thanks for your interest in contributing to Mintacoin, any contribution is greatly appreciated.

For more information on how to contribute, please refer to our [CONTRIBUTING][contributing] guide.

**First time contributing?** Check out these [good first issues][good-first-issues] to get you started!

## License

This library is licensed under an MIT license. See [LICENSE][license] for details.

## Credits

Special thanks to the third party tools used in this project.

[<img src="https://user-images.githubusercontent.com/39246879/198380259-b9615598-0dd2-4a35-9402-c7ac2896fa53.svg"  width="250" height="100">][gitbook]

[GitBook][gitbook] is the sponsor platform for the publishing of our documentation.

## Acknowledgements

Made with 💙 by [kommitters Open Source](https://kommit.co)

[banner-img]: https://user-images.githubusercontent.com/1649973/170068587-1b4c1b0d-9b48-46d1-9aed-f99d1b2b84f8.png
[www]: https://www.mintacoin.co
[stellar]: https://www.stellar.org/
[roadmap]:https://github.com/orgs/kommitters/projects/6/views/6
[stellar-laboratory]: (https://laboratory.stellar.org/#account-creator?network=test)
[good-first-issues]: https://github.com/kommitters/mintacoin/issues?q=is%3Aissue+is%3Aopen+label%3A%22%F0%9F%91%8B+Good+first+issue%22
[api-documentation]: https://docs.mintacoin.co
[changelog]: https://github.com/kommitters/mintacoin/blob/main/CHANGELOG.md
[coc]: https://github.com/kommitters/mintacoin/blob/main/CODE_OF_CONDUCT.md
[contributing]: https://github.com/kommitters/mintacoin/blob/main/CONTRIBUTING.md
[license]: https://github.com/kommitters/mintacoin/blob/main/LICENSE
[gitbook]: https://www.gitbook.com/
