# Gamification Event System

A gamification system that manages user events related to virtual coins, using ETS (Erlang Term Storage) for in-memory storage. 
This project was created as a personal challenge to build a complete system using only Elixir's standard library, without relying on any external packages. 
The goal was to demonstrate Elixir's capabilities in handling complex business logic and data management using only its built-in features.

While this project doesn't strictly follow Domain-Driven Design (DDD), it incorporates some of its principles to maintain clean and well-separated code. The business rules are encapsulated within their respective modules, and the domain logic is separated from the infrastructure concerns (like storage).

While there's always room for improvement and evolution, I've decided to stop here as I'm satisfied with the current implementation. The project successfully demonstrates how to build a clean, maintainable system using pure Elixir, and further enhancements would likely add unnecessary complexity without significant benefits.

## Description

This project implements a gamification system that allows:
- Receiving virtual coins (`amount_received`)
- Requesting virtual coins (`amount_requested`)
- Managing user coin balances
- Validating business rules for each operation

## Requirements

- Elixir ~> 1.14
- Erlang/OTP 25

## Installation

1. Clone the repository
2. Run `mix compile` to compile the project

## How to Run

To start the project in interactive mode:

```bash
iex -S mix
```

## Event Format

Events must follow the JSON format below:

```
{
  "event": "amount_received" | "amount_requested",
  "user_id": <integer>,
  "amount": <integer>,
  "created_at": <ISO 8601 string>
}
```

## Business Rules

### `amount_received` Events
- The received amount must be positive
- The maximum allowed amount is 5000 coins

### `amount_requested` Events
- The requested amount must be positive
- The maximum allowed amount is 1000 coins
- The user must have sufficient balance to cover the requested amount
- Users can request a maximum of 3 times per minute

## Project Structure

- `lib/gamification_event.ex` - Main module that manages events and contains core business logic
- `lib/gamification_event_parser.ex` - Handles input data parsing and validation
- `lib/gamification_event_store.ex` - Manages event and balance storage (infrastructure layer)
- `lib/ets_tables.ex` - ETS tables configuration (infrastructure layer)
- `lib/start_here.ex` - Application entry point for using the """"INTERFACE""""

## Storage

The system uses ETS (Erlang Term Storage) to store:
- User coin balances
- Event history

## Usage Examples

### Receiving Coins
```json
{
  "event": "amount_received",
  "user_id": 123,
  "amount": 100,
  "created_at": "2024-03-20T10:00:00Z"
}
```

### Requesting Coins
```json
{
  "event": "amount_requested",
  "user_id": 123,
  "amount": 50,
  "created_at": "2024-03-20T10:00:00Z"
}
```

## System Responses

### Success
```json
{
  "user_id": 123,
  "coins_balance": 150
}
```

### Possible Errors
- `{"error": "missing_required_fields"}`
- `{"error": "amount_received_cannot_be_negative"}`
- `{"error": "amount_received_exceeded_limit"}`
- `{"error": "amount_requested_cannot_be_negative"}`
- `{"error": "amount_requested_exceeded_limit"}`
- `{"error": "user_has_insufficient_funds"}`
- `{"error": "user_amount_requested_per_minute_limit_exceeded"}`
- `{"error": "invalid_event"}`
- `{"error": "invalid_input"}`