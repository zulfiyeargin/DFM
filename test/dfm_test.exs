defmodule DfmTest do
  use ExUnit.Case, async: true

  @sample_file Path.join(File.cwd!(), "test/fixture/test_file.csv")

  describe "Read test_file.csv and build traces" do
    traces = [trace1 | _] = DFM.build_traces(@sample_file)

    assert length(traces) == 5
    assert length(trace1.events) == 4
    assert trace1.start_time == ~U[2015-01-04 12:09:44.000Z]
    assert trace1.finish_time == ~U[2016-01-04 12:48:44.000Z]
  end

  describe "Build direct follower matrix" do
    matrix =
      DFM.build_traces(@sample_file)
      |> DFM.build_matrix()

    assert matrix["step1"]["step2"] == 5
    assert matrix["step2"]["step3"] == 5
    assert matrix["step3"]["step4"] == 5
    assert matrix["step4"]["step3"] == 0
    assert matrix["step1"]["step3"] == 0
  end

  describe "Filter traces which are started after 2016:01:01" do
    traces = DFM.build_traces(@sample_file)

    filtered_matrix1 =
      traces
      |> DFM.filter_results(~U[2016-01-01 00:00:00.000Z], ~U[2022-01-01 00:00:00.000Z])

    assert filtered_matrix1["step1"]["step2"] == 4
    assert filtered_matrix1["step3"]["step4"] == 4
  end

  describe "Filter traces which are started after 2016:01:01 and finished before 2018-01-01" do
    traces = DFM.build_traces(@sample_file)

    filtered_matrix1 =
      traces
      |> DFM.filter_results(~U[2016-01-01 00:00:00.000Z], ~U[2018-01-01 00:00:00.000Z])

    assert filtered_matrix1["step1"]["step2"] == 3
    assert filtered_matrix1["step3"]["step4"] == 3
  end
end
