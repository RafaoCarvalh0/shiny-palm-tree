defmodule GamificationEventTest do
  use ExUnit.Case
  alias GamificationEvent

  describe "create_user_gamification_event/1" do
    test "validates required fields" do
      raw_data = ~s({"event": "amount_received", "amount": 100})

      assert "{\"error\": \"missing_required_fields\"}" =
               GamificationEvent.create_user_gamification_event(raw_data)
    end

    test "validates amount_received limit" do
      raw_data =
        ~s({"event": "amount_received", "user_id": 1, "amount": 6000, "created_at": "2024-03-20T10:00:00Z"})

      assert "{\"error\": \"amount_received_exceeded_limit\"}" =
               GamificationEvent.create_user_gamification_event(raw_data)
    end

    test "validates amount_requested limit" do
      raw_data =
        ~s({"event": "amount_requested", "user_id": 1, "amount": 1500, "created_at": "2024-03-20T10:00:00Z"})

      assert "{\"error\": \"amount_requested_exceeded_limit\"}" =
               GamificationEvent.create_user_gamification_event(raw_data)
    end

    test "validates negative amount_requested" do
      raw_data =
        ~s({"event": "amount_requested", "user_id": 1, "amount": -100, "created_at": "2024-03-20T10:00:00Z"})

      assert "{\"error\": \"amount_requested_cannot_be_negative\"}" =
               GamificationEvent.create_user_gamification_event(raw_data)
    end

    test "validates invalid event type" do
      raw_data =
        ~s({"event": "invalid_event", "user_id": 1, "amount": 100, "created_at": "2024-03-20T10:00:00Z"})

      assert "{\"error\": \"invalid_event\"}" =
               GamificationEvent.create_user_gamification_event(raw_data)
    end
  end
end
