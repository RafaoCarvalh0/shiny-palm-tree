defmodule GamificationEventStoreTest do
  use ExUnit.Case

  alias GamificationEventStore

  setup do
    EtsTables.start()
    :ok
  end

  describe "get_user_balance_by_id/1" do
    test "returns nil when user does not exist" do
      assert GamificationEventStore.get_user_balance_by_id(123) == nil
    end

    test "returns user balance when user exists" do
      user_id = 123
      coins_balance = 100

      GamificationEventStore.insert_or_update_user_balance(user_id, coins_balance)

      assert GamificationEventStore.get_user_balance_by_id(user_id) == %{
               user_id: user_id,
               coins_balance: coins_balance
             }
    end
  end

  describe "insert_or_update_user_balance/2" do
    test "inserts new user balance" do
      user_id = 123
      coins_balance = 100

      result = GamificationEventStore.insert_or_update_user_balance(user_id, coins_balance)

      assert result == %{
               user_id: user_id,
               coins_balance: coins_balance
             }
    end

    test "updates existing user balance" do
      user_id = 123
      initial_balance = 100
      updated_balance = 200

      GamificationEventStore.insert_or_update_user_balance(user_id, initial_balance)
      result = GamificationEventStore.insert_or_update_user_balance(user_id, updated_balance)

      assert result == %{
               user_id: user_id,
               coins_balance: updated_balance
             }
    end
  end

  describe "insert_user_gamification_event/1" do
    test "inserts new event successfully" do
      event_map = %{
        event: "test_event",
        user_id: 123,
        amount: 100,
        created_at: ~N[2024-04-08 12:00:00]
      }

      assert GamificationEventStore.insert_user_gamification_event(event_map) == true
    end

    test "does not fail when trying to insert duplicate event" do
      event_map = %{
        event: "test_event",
        user_id: 123,
        amount: 100,
        created_at: ~N[2024-04-08 12:00:00]
      }

      assert GamificationEventStore.insert_user_gamification_event(event_map) == true
      assert GamificationEventStore.insert_user_gamification_event(event_map) == true
    end
  end

  describe "get_user_gamification_events_between_dates/4" do
    test "returns events within date range" do
      user_id = 123
      event = "test_event"
      now = DateTime.utc_now()
      one_minute_ago = DateTime.add(now, -60, :second)
      one_minute_ahead = DateTime.add(now, 60, :second)

      event_map = %{
        event: event,
        user_id: user_id,
        amount: 100,
        created_at: NaiveDateTime.from_iso8601!(DateTime.to_string(now))
      }

      GamificationEventStore.insert_user_gamification_event(event_map)

      events =
        GamificationEventStore.get_user_gamification_events_between_dates(
          user_id,
          event,
          one_minute_ago,
          one_minute_ahead
        )

      assert length(events) == 1
      [result] = events
      assert result.event == event
      assert result.user_id == user_id
      assert result.amount == 100
    end

    test "returns empty list when no events in date range" do
      user_id = 123
      event = "test_event"
      now = DateTime.utc_now()
      two_minutes_ago = DateTime.add(now, -120, :second)
      one_minute_ago = DateTime.add(now, -60, :second)

      event_map = %{
        event: event,
        user_id: user_id,
        amount: 100,
        created_at: NaiveDateTime.from_iso8601!(DateTime.to_string(now))
      }

      GamificationEventStore.insert_user_gamification_event(event_map)

      events =
        GamificationEventStore.get_user_gamification_events_between_dates(
          user_id,
          event,
          two_minutes_ago,
          one_minute_ago
        )

      assert events == []
    end
  end
end
