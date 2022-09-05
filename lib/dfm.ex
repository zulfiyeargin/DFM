defmodule DFM do
  @moduledoc """
  A Lana Labs test task - Direct Followers matrix.
  """
  alias DFM.Event

  @buffer_size 128 * 1024
  @forward_char "/"
  @dash_char "-"
  @utc_char "Z"
  @beginning_of_time ~U[0001-01-01 00:00:00Z]
  @example_path Path.join(:code.priv_dir(:dfm), "IncidentExample.csv")

  @spec build_traces(string) :: [DFM.Trace]
  def build_traces(path \\ @example_path) do
    # parses input file, group them by case id's and create traces
    path
    |> parse_file()
    |> Enum.group_by(& &1[:case_id], & &1[:event])
    |> Enum.map(fn {case_id, event_list} -> DFM.Trace.create_trace(case_id, event_list) end)
  end

  @spec build_matrix([DFM.Trace]) :: %{}
  def build_matrix(trace_list) do
    # create an empty map and update it for each trace.events
    trace_list
    |> Enum.reduce(%{}, fn trace, matrix ->
      trace.events
      |> (&update_event_counts(matrix, &1)).()
    end)
  end

  @spec filter_results([DFM.Trace], DateTime, DateTime) :: %{}
  def filter_results(trace_list, %DateTime{} = range_start, %DateTime{} = range_end) do
    trace_list
    |> Enum.filter(fn trace ->
      case DateTime.compare(trace.start_time, range_start) do
        :lt ->
          false

        _ ->
          case DateTime.compare(trace.finish_time, range_end) do
            :gt ->
              false

            _ ->
              true
          end
      end
    end)
    |> build_matrix
  end

  defp parse_file(file_path) do
    file_path
    |> File.stream!(read_ahead: @buffer_size)
    |> NimbleCSV.RFC4180.parse_stream()
    |> Stream.map(&create_event_with_id(&1))
  end

  defp create_event_with_id([case_id, activity, start_time, end_time, _classification]) do
    %{
      case_id: case_id,
      event: %Event{
        activity: activity,
        start_time: convert_datetime(start_time),
        end_time: convert_datetime(end_time)
      }
    }
  end

  defp convert_datetime(datetime_str) do
    result =
      datetime_str
      |> String.replace(@forward_char, @dash_char)
      |> Kernel.<>(@utc_char)
      |> DateTime.from_iso8601()

    case result do
      {:ok, datetime, 0} ->
        datetime

      _other ->
        @beginning_of_time
    end
  end

  defp update_event_counts(matrix, [_event]), do: matrix

  defp update_event_counts(matrix, [event1, event2 | rest]) do
    expanded_matrix = expand_matrix_with_new_activities?(matrix, event1.activity, event2.activity)

    expanded_matrix
    |> Map.get(event1.activity)
    |> Map.update!(event2.activity, &(&1 + 1))
    |> (&Map.put(expanded_matrix, event1.activity, &1)).()
    |> update_event_counts([event2 | rest])
  end

  defp expand_matrix_with_new_activities?(matrix, activity1, activity2) do
    # add all activities as rows and columns if they are not already in the matrix
    matrix
    |> Map.put_new(activity1, %{})
    |> Map.put_new(activity2, %{})
    |> Enum.reduce(matrix, fn {key, sub_map}, acc ->
      sub_map
      |> Map.put_new(activity1, 0)
      |> Map.put_new(activity2, 0)
      |> (&Map.put(acc, key, &1)).()
    end)
  end
end
