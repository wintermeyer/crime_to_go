defmodule CrimeToGoWeb.BaseLive do
  @moduledoc """
  Base LiveView module that provides common functionality for all LiveViews.
  """

  defmacro __using__(_opts) do
    quote do
      import CrimeToGoWeb.LocaleHelpers
    end
  end
end
