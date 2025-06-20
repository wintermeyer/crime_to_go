defmodule CrimeToGo.Shared.NicknameGenerator do
  @moduledoc """
  Handles nickname generation for players with internationalization support.
  
  This module provides functions for:
  - Generating default detective nicknames based on game language
  - Checking nickname availability
  - Getting localized detective name lists
  """

  @doc """
  Generates a default nickname for a player based on the game language.
  
  Uses detective character names from different cultures/languages to provide
  appropriate defaults for each supported locale.
  
  ## Examples
  
      NicknameGenerator.generate_default_nickname(existing_players, "en")
      #=> "Holmes"
      
      NicknameGenerator.generate_default_nickname(existing_players, "de") 
      #=> "Derrick"
  """
  def generate_default_nickname(existing_players, game_lang) do
    detective_names = get_detective_names_for_locale(game_lang)
    taken_nicknames = get_taken_nicknames(existing_players)
    
    # Find first available detective name
    available_name = 
      detective_names
      |> Enum.find(&(not MapSet.member?(taken_nicknames, &1)))
    
    # If all detective names are taken, generate a numbered variant
    case available_name do
      nil -> generate_numbered_nickname(detective_names, taken_nicknames)
      name -> name
    end
  end

  @doc """
  Gets the list of detective names for a specific locale.
  
  ## Examples
  
      NicknameGenerator.get_detective_names_for_locale("en")
      #=> ["Holmes", "Poirot", "Marple", ...]
  """
  def get_detective_names_for_locale(locale) do
    case locale do
      "en" -> english_detective_names()
      "de" -> german_detective_names()
      "es" -> spanish_detective_names()
      "fr" -> french_detective_names()
      "it" -> italian_detective_names()
      "ru" -> russian_detective_names()
      "tr" -> turkish_detective_names()
      "uk" -> ukrainian_detective_names()
      _ -> english_detective_names() # Default fallback
    end
  end

  @doc """
  Checks if a nickname is available (not taken by existing players).
  
  ## Examples
  
      NicknameGenerator.nickname_available?(players, "Holmes")
      #=> false
  """
  def nickname_available?(existing_players, nickname) do
    taken_nicknames = get_taken_nicknames(existing_players)
    not MapSet.member?(taken_nicknames, nickname)
  end

  @doc """
  Gets all taken nicknames from the player list.
  
  ## Examples
  
      NicknameGenerator.get_taken_nicknames(players)
      #=> #MapSet<["Holmes", "Watson", "Poirot"]>
  """
  def get_taken_nicknames(existing_players) do
    existing_players
    |> Enum.map(& &1.nickname)
    |> Enum.reject(&is_nil/1)
    |> MapSet.new()
  end

  @doc """
  Suggests available nicknames based on the game language.
  
  Returns a list of available detective names that can be used as suggestions.
  
  ## Examples
  
      NicknameGenerator.suggest_available_nicknames(players, "en", 5)
      #=> ["Marple", "Columbo", "Monk", "Castle", "Beckett"]
  """
  def suggest_available_nicknames(existing_players, game_lang, count \\ 5) do
    detective_names = get_detective_names_for_locale(game_lang)
    taken_nicknames = get_taken_nicknames(existing_players)
    
    detective_names
    |> Enum.reject(&MapSet.member?(taken_nicknames, &1))
    |> Enum.shuffle()
    |> Enum.take(count)
  end

  # ============================================================================
  # PRIVATE DETECTIVE NAME LISTS
  # ============================================================================

  defp english_detective_names do
    [
      "Holmes", "Watson", "Poirot", "Marple", "Columbo", "Monk", "Castle", 
      "Beckett", "Morse", "Lewis", "Frost", "Vera", "Endeavour", "Dalziel",
      "Pascoe", "Rebus", "Lynley", "Havers", "Jury", "Plant", "Wexford",
      "Burden", "Barnaby", "Troy", "Jones", "Winter", "Spencer", "Hawk"
    ]
  end

  defp german_detective_names do
    [
      "Derrick", "Klein", "Schimanski", "Thiel", "Boerne", "Lessing",
      "Ballauf", "Schenk", "Odenthal", "Stern", "Ehrlicher", "Kain",
      "Flemming", "Wolff", "Casstorff", "Ritter", "Karow", "Rubin",
      "Lindholm", "Gorniak", "Winkler", "Schnabel", "Brasch", "Herzog"
    ]
  end

  defp spanish_detective_names do
    [
      "Mendez", "Vargas", "Castillo", "Herrera", "Morales", "Jimenez",
      "Ruiz", "Fernandez", "Lopez", "Gonzalez", "Martinez", "Sanchez",
      "Perez", "Garcia", "Rodriguez", "Alvarez", "Romero", "Torres",
      "Ramirez", "Flores", "Rivera", "Gutierrez", "Diaz", "Cruz"
    ]
  end

  defp french_detective_names do
    [
      "Maigret", "Adamsberg", "Camille", "Verhoeven", "Bourrel", "Courrèges",
      "Dupin", "Rouletabille", "Nestor", "Burma", "San-Antonio", "Commissaire",
      "Inspecteur", "Capitaine", "Lieutenant", "Brigadier", "Adjudant",
      "Gendarme", "Juge", "Procureur", "Avocat", "Témoin", "Suspect", "Coupable"
    ]
  end

  defp italian_detective_names do
    [
      "Montalbano", "Coliandro", "Rocco", "Schiavone", "Nero", "Wolfe",
      "Brunetti", "De Luca", "Bordelli", "Ricciardi", "Mascherpa", "Cattani",
      "Corte", "Manara", "Germano", "Cecchini", "Anceschi", "Toscani",
      "Romano", "Lombardi", "Ferrari", "Marino", "Greco", "Bruno"
    ]
  end

  defp russian_detective_names do
    [
      "Порфирий", "Достоевский", "Раскольников", "Печорин", "Карамазов",
      "Безухов", "Болконский", "Левин", "Вронский", "Каренина", "Наташа",
      "Соня", "Катюша", "Дуня", "Лиза", "Вера", "Варя", "Маша", "Саша",
      "Паша", "Даша", "Глаша", "Клаша", "Степан"
    ]
  end

  defp turkish_detective_names do
    [
      "Mehmet", "Ahmet", "Mustafa", "Ali", "Hasan", "Hüseyin", "İbrahim",
      "Osman", "Yusuf", "Kemal", "Abdullah", "Ömer", "Süleyman", "Recep",
      "Fatma", "Ayşe", "Emine", "Hatice", "Zeynep", "Elif", "Merve",
      "Özge", "Seda", "Burcu", "Gizem", "Cansu", "Duygu", "Ebru"
    ]
  end

  defp ukrainian_detective_names do
    [
      "Олександр", "Михайло", "Андрій", "Володимир", "Василь", "Іван", "Петро",
      "Дмитро", "Сергій", "Олег", "Юрій", "Віктор", "Анатолій", "Валерій",
      "Оксана", "Тетяна", "Наталія", "Ірина", "Олена", "Людмила", "Ганна",
      "Світлана", "Марія", "Валентина", "Ніна", "Віра", "Надія", "Любов"
    ]
  end

  # ============================================================================
  # PRIVATE HELPERS
  # ============================================================================

  defp generate_numbered_nickname(detective_names, taken_nicknames) do
    # Take the first detective name and add numbers until we find an available one
    base_name = List.first(detective_names) || "Detective"
    
    1..100
    |> Enum.find_value(fn num ->
      candidate = "#{base_name}#{num}"
      if not MapSet.member?(taken_nicknames, candidate) do
        candidate
      end
    end) || "Player#{:rand.uniform(9999)}" # Ultimate fallback
  end
end