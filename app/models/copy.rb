#AirRecord  https://github.com/sirupsen/airrecord
Airrecord.api_key = ENV['API_KEY']

class Copy < Airrecord::Table
  self.base_key = "appXZ2SAGdLGAePT3"
  self.table_name = "Table 1"
end
