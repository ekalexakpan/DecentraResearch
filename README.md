# DecentraResearch

DecentraResearch is a decentralized peer review and research funding platform built on Stacks blockchain. It enables transparent, community-driven evaluation of research proposals and democratic allocation of research funding.

## Features

- **Credit-Based System**: Researchers earn credits based on their contributions and reputation
- **Peer Review Network**: Distributed review process ensures quality and reduces bias
- **Transparent Funding**: Community-driven funding decisions based on peer evaluations
- **Data Integrity**: Immutable record of research submissions and reviews

## Smart Contract Functions

### Credit Management
- `mint-research-credits`: Issue credits to researchers and institutions
- `transfer-credits`: Transfer credits between researchers
- `get-researcher-credits`: Check researcher's credit balance

### Research Workflow
- `submit-study`: Submit research proposal for peer review
- `peer-review`: Evaluate submitted research studies
- `finalize-funding`: Complete review process and determine funding
- `get-study`: Retrieve research study details

## Getting Started

1. Clone this repository
2. Install [Clarinet](https://github.com/hirosystems/clarinet)
3. Run `clarinet check` to verify the contract
4. Deploy using Clarinet or Stacks CLI