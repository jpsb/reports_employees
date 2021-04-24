defmodule ReportsEmployees do
  alias ReportsEmployees.Parser

  @available_users [
    :daniele,
    :mayk,
    :giuliano,
    :cleiton,
    :jakeliny,
    :joseph,
    :diego,
    :danilo,
    :rafael,
    :vinicius
  ]

  @months [
    :janeiro,
    :fevereiro,
    :marco,
    :abril,
    :maio,
    :junho,
    :julho,
    :agosto,
    :setembro,
    :outubro,
    :novembro,
    :dezembro
  ]

  @years [
    "2016",
    "2017",
    "2018",
    "2019",
    "2020"
  ]

  def build(filename) do
    filename
    |> Parser.parse_file()
    |> Enum.reduce(report_acc(), fn line, report -> sum_values(line, report) end)
  end

  def build_from_many(filenames) when not is_list(filenames) do
    {:error, "Please provide a list of strings"}
  end

  def build_from_many(filenames) do
    result =
      filenames
      |> Task.async_stream(&build/1)
      |> Enum.reduce(report_acc(), fn {:ok, result}, report -> sum_report(report, result) end)

    {:ok, result}
  end

  defp sum_report(
         %{
           all_hours: all_hours1,
           hours_per_month: hours_per_month1,
           hours_per_year: hours_per_year1
         },
         %{
           all_hours: all_hours2,
           hours_per_month: hours_per_month2,
           hours_per_year: hours_per_year2
         }
       ) do
    all_hours = merge_maps(all_hours1, all_hours2)

    hours_per_month =
      Map.merge(hours_per_month1, hours_per_month2, fn _key, user1, user2 ->
        merge_maps(user1, user2)
      end)

    hours_per_year =
      Map.merge(hours_per_year1, hours_per_year2, fn _key, user1, user2 ->
        merge_maps(user1, user2)
      end)

    build_report(all_hours, hours_per_month, hours_per_year)
  end

  defp merge_maps(map1, map2) do
    Map.merge(map1, map2, fn _key, value1, value2 -> value1 + value2 end)
  end

  defp sum_values(
         [user_name, hours, _day, month, year],
         %{
           all_hours: all_hours,
           hours_per_month: hours_per_month,
           hours_per_year: hours_per_year
         }
       ) do
    user = String.to_atom(user_name)
    all_hours = Map.put(all_hours, user, all_hours[user] + hours)

    month_desc = Enum.at(@months, month - 1)
    hours_per_month = refresh_values(hours_per_month, user, month_desc, hours)

    hours_per_year = refresh_values(hours_per_year, user, String.to_atom(year), hours)

    build_report(all_hours, hours_per_month, hours_per_year)
  end

  defp refresh_values(collection, user, key, hours) do
    user_hours_per_year = collection[user]
    user_hours_per_year = Map.put(user_hours_per_year, key, user_hours_per_year[key] + hours)
    Map.put(collection, user, user_hours_per_year)
  end

  defp report_acc do
    months = Enum.into(@months, %{}, &{&1, 0})
    years = Enum.into(@years, %{}, &{String.to_atom(&1), 0})

    all_hours = Enum.into(@available_users, %{}, &{&1, 0})
    hours_per_month = Enum.into(@available_users, %{}, &{&1, months})
    hours_per_year = Enum.into(@available_users, %{}, &{&1, years})

    build_report(all_hours, hours_per_month, hours_per_year)
  end

  defp build_report(all_hours, hours_per_month, hours_per_year) do
    %{
      all_hours: all_hours,
      hours_per_month: hours_per_month,
      hours_per_year: hours_per_year
    }
  end
end
