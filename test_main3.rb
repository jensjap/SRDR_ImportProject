require "test/unit"
require "logger"
require_relative "main3"

FILENAME = "data/ap2dataout.xlsx"

class TestMain < Test::Unit::TestCase
  def setup
    @log = Logger.new(STDOUT)
  end

  def test_load_study_data
    study_data_header, study_data_rows = load_study_data(FILENAME, @log)
    assert_equal(study_data_header.length, 600)
    assert_equal(study_data_rows.length, 129)
  end

  def test_build_header_2_column_id_lookup_table
    study_data_header, study_data_rows = load_study_data(FILENAME, @log)
    map = build_header_2_column_id_lookup_table(study_data_header)
    #p map.inspect
    assert_equal(0,   map["CaseId"])
    assert_equal(160, map["outcome1"])
    assert_equal(250, map["int_2_4"])
    assert_equal(599, map["XX"])
  end
end
