defmodule DFM.Trace do
  @moduledoc """
  A sequence of *events* in process mining.

  Correspond to one instance of a certain *process*, for example:

  - an insurance claim which is processed in multiple steps at an insurance company
  - customer support ticket processing
  - conveyor belt manufacturing.

  Each event is represented as `DFM.Event` struct.
  """

  defstruct [:id, :events, :start_time, :finish_time]

  @type t() :: %__MODULE__{
          id: any(),
          events: [DFM.Event.t()],
          start_time: DateTime.t(),
          finish_time: DateTime.t()
        }
  def create_trace(case_id, event_list) do
    sorted_events =
      Enum.sort(
        event_list,
        &(DateTime.compare(&1.start_time, &2.start_time) != :gt)
      )

    start_time =
      sorted_events
      |> Enum.at(0)
      |> Map.get(:start_time)

    %__MODULE__{
      id: case_id,
      events: sorted_events,
      start_time: start_time,
      finish_time: calculate_finish_time(sorted_events)
    }
  end

  defp calculate_finish_time([event]) do
    event.end_time
  end

  defp calculate_finish_time([event1, event2 | rest]) do
    case(DateTime.compare(event1.end_time, event2.end_time)) do
      :gt ->
        calculate_finish_time([event1 | rest])

      _ ->
        calculate_finish_time([event2 | rest])
    end
  end
end
