# aVa Reputation System

## Overview

The aVa Reputation System is a decentralized reputation management solution built on the Internet Computer platform. It allows users to earn, manage, and track reputation across various domains and categories.

### Features

- Decentralized reputation tracking
- Hierarchical category system
- Namespace-based reputation updates
- User and category management
- Reputation history tracking
- Integration with ICRC-72 for event handling

## Getting Started
###Prerequisites

- Dfinity's dfx CLI tool

## Installation

1. Clone the repository:
   
```
git clone https://github.com/Vitiv/derep
cd ava-reputation-system
```

2. Deploy:
```
dfx start --background
dfx deploy
```


## Usage
The main canister for interacting with the reputation system is ReputationActor. Here are some key functions:

updateReputation(user: Principal, category: Text, value: Int)
getUserReputation(userId: UserId, categoryId: CategoryId)
createCategory(id: Text, name: Text, description: Text, parentId: ?Text)
determineCategories(namespace: Text, documentUrl: ?Text)

For a complete list of available functions, please refer to the ReputationActor.mo file.

## Architecture

The project follows a clean architecture approach with the following key components:

- Entities: Core business objects
- Use Cases: Application-specific business rules
- Repositories: Data access interfaces
- Infrastructure: External interfaces and implementations

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License
This project is licensed under the MIT License.

