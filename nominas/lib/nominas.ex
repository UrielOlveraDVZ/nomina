defmodule Nominas do
  defmodule SatField do
    defstruct [:code, :field, :message, :sat_error_code, :sat_error_message]
  end

  def handle() do
    #READ FILE
    path_file = ~s(/home/dozenth/Codes/DVZ/Complemento Nominas/insumosXML/01.xml)
    xml = case File.read(path_file) do
      {:ok, xml} -> xml
      {:error, x} -> IO.inspect({:error, x})
    end
    xml_document = :erlang.bitstring_to_list(xml)
    {:ok, xml_document} = read(xml_document)

    #RULES DEFINITION
    rule_name = :rule_name
    rule = {

    }

    check({rule_name, rule}, xml_document)
  end
  #RULES FUNCTIONS
  def check({:rule_name, rule}, xml_document) do
    {:ok, ""}
  end

  # --------------------------------------------------------------------------------------------------------------------

  def build_response_struct(field, system_message, sat_code, sat_message) do
    %SatField{
      code: 1450,
      field: field,
      message: system_message,
      sat_error_code: sat_code,
      sat_error_message: convert_to_utf8(sat_message)
    }
  end

  def read (xml) do
    try do
      {xml_document, _} = :xmerl_scan.string(xml, [{:namespace_conformant, true}])
      {:ok, xml_document}
    catch
      :exit, _ -> {:error, "invalid xml file, xml can't be parsed"}
    end
  end

  def query(xpath, xml) do
    case :xmerl_xpath.string('#{xpath}', xml) do
      [result] ->
        res = elem(result, 8)
        case is_list(res) do
          true ->
            res
          false ->
            res
            |> to_string
            |> String.strip
        end
      [head | _] ->
        res = elem(head, 8)
        case is_list(res) do
          true ->
            res
          false ->
            res
            |> to_string
            |> String.strip
        end
      [] -> []
    end
  end

  def query_multiple(xpath, xml) do
    case :xmerl_xpath.string('#{xpath}', xml) do
      [head | tail] -> [head | tail]
      [] -> []
    end
  end

  def convert_to_utf8(data) do
    cond do
      is_nil(data) ->
        :nil
      true ->
        case String.valid?(data) do
          false ->
            Enum.join(for <<c <- data>>, do: <<c :: utf8>>)
          true ->
            data
        end
    end
  end

  def find_rfc(value) do
    value
  end

  def get_country(country) do
    #  ConCache.put(:country_catalog, "DEU", {~r/^.*$/,~r/^.*$/,"","Union Europea"})
    #  ConCache.put(:country_catalog, "CAN", {~r/^[A-Z][0-9][A-Z] [0-9][A-Z][0-9]$/,~r/^[0-9]{9}$/,"","TLCAN"})
    #  ConCache.put(:country_catalog, "USA", {~r/^[0-9]{5}(-[0-9]{4})?$/,~r/^[0-9]{9}$/,"","TLCAN"})
    #  ConCache.put(:country_catalog, "MEX", {~r/^[0-9]{5}$/,~r/^[A-Z&Ñ]{3,4}[0-9]{2}(0[1-9]|1[012])(0[1-9]|[12][0-9]|3[01])[A-Z0-9]{2}[0-9A]$/,"","TLCAN"})

    #  {
    #    Formato de código postal,
    #    Formato de Registro de Identidad Tributaria,
    #    Validación del Registro de Identidad Tributaria,
    #    Agrupaciones
    #  }

    #  {
    #    ~r/^[0-9]{5}$/,
    #    ~r/^[A-Z&Ñ]{3,4}[0-9]{2}(0[1-9]|1[012])(0[1-9]|[12][0-9]|3[01])[A-Z0-9]{2}[0-9A]$/,
    #    "",
    #    "TLCAN"
    #  }

    {
      ~r/^[A-Z][0-9][A-Z] [0-9][A-Z][0-9]$/,
      ~r/^[0-9]{9}$/,
      "",
      "TLCAN"
    }
  end

  def get_unity(_unity) do
    {"", "", "", "yd/psi", "Volumen"}
    #nil
  end

  def get_clave(_clave) do
    #{"0", "", ""}
  :ok
  end

  defp get_material_peligroso(item) do
    {"1.1D"}
  end

  defp get_zip_code(zip_code) do
    {"NLE",
      "039",
      "07",
      "0",
      "43472",
      "43752",
      "Tiempo del Centro",
      "Abril",
      "Primer domingo",
      "02:00",
      "-5",
      "Octubre	",
      "Último domingo",
      "02:00",
      "-6"
    }
  end

  def get_station(station) do
    :nil
    :ok
  end

  def get_state(state) do
    if "WWW" == state || "XXX" == state do
      :nil
    else
      state
    end
  end

  def get_city(city) do
    #    :nil
    {"001","AGU"}
  end
end
