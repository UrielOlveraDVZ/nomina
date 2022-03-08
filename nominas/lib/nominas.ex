defmodule Nominas do
  defmodule SatField do
    defstruct [:code, :field, :message, :sat_error_code, :sat_error_message]
  end

  def handle() do
    #READ FILE
    path_file = ~s(C:/Users/ale_b/Desktop/DVZ/nomina/insumosXML/01.xml)
    xml = case File.read(path_file) do
      {:ok, xml} -> xml
      {:error, x} -> IO.inspect({:error, x})
    end
    xml_document = :erlang.bitstring_to_list(xml)
    {:ok, xml_document} = read(xml_document)

    #RULES DEFINITION
    rule_name = :conditional_prensece_of_field
    rule = {
      :RCurp, :path, '//nomina12:Receptor/@Curp',
      :rfc, :path, '//cfdi:Comprobante/cfdi:Receptor/@Rfc',
      :regex,~r/^XAXX010101000$/,
      :sat_error_code,"NOM10",
      :sat_error_message,"El atributo Comprobante.Receptor.Rfc registra el RFC genérico XAXX010101000, por lo que en el atributo Nomina12:Receptor:Curp, debe registrar la CURP del receptor fallecido."
    }

    IO.inspect(check({rule_name, rule}, xml_document))
  end


  #RULES FUNCTIONS
  def check({:conditional_prensece_of_field, rule}, xml_document) do
    {field,_,path,
    cond_rule,_,cond_path,
    cond_field,regex,
    _,sat_code,
    _,sat_message} = rule
    cond_value = query(cond_path, xml_document)

    case String.match?(to_string(cond_value), regex) do
      true ->
        IO.puts "NOOOO"
        result = validate_presence(path, xml_document)
        cond do
          result == true -> {:ok, field}
          true ->
            system_message = "The field #{field} must contian value when #{cond_field} is #{cond_rule}"
            {:error, build_response_struct(field, system_message, sat_code, sat_message)}
        end
      false ->
        IO.puts "SIIIIII"
        {:ok, field}
    end
  end


  defp validate_presence(path,xml_document) do
    case query_multiple(path,xml_document) do
      [] -> false
      _ -> true
    end
  end

  def check({:validate_item_presence, rule}, xml_document) do
    {
      field,
      path,
      _,
      system_message,
      _,
      sat_error_code,
      _,
      sat_error_message
    } = rule

    case query_multiple(path, xml_document) do
      [] -> {:error}
      _ -> {:ok}
    end
  end
  def check({:validate_item_absence, rule}, xml_document) do
    {
      field,
      path,
      _,
      system_message,
      _,
      sat_error_code,
      _,
      sat_error_message
    } = rule

    case query_multiple(path, xml_document) do
      _ -> {:error}
      [] -> {:ok}
    end
  end

  # # NOM3-------------------------------------------------------------------------------------------
  # field_value: {
  #   :Exportacion,:path,'//cfdi:Comprobante/@Exportacion',
  #   :value,'01',:sat_error_code,"NOM3",
  #   :sat_error_message,"En el atributo Comprobante.Exportacion, se debe registrar la clave 01."},

  # # NOM4-------------------------------------------------------------------------------------------
  # absence_of_node: {
  #   :InformacionGlobal,:path,'//cfdi:Comprobante/cfdi:InformacionGlobal',
  #   :sat_error_code,"NOM4",
  #   :sat_error_message,"El nodo Comprobante.InformacionGlobal, no debe existir."},

  # # NOM7------------------------------------------------------------------------------------------------
  # absence_of_field: {
  #   :FacAtrAdquirente,:path,'//cfdi:Comprobante/cfdi:Emisor/@FacAtrAdquirente',
  #   :sat_error_code,"NOM7",
  #   :sat_error_message,"El atributo Comprobante.Emisor.FacAtrAdquirente, no debe existir."},

  # # NOM10------------------------------------------------------------------------------------------------
  # conditional_prensece_of_field: {
  #   :RCurp, :path, '//nomina12:Receptor/@Curp',
  #   :rfc, :path, '//cfdi:Comprobante/cfdi:Receptor/@Rfc',
  #   :regex,~r/^XAXX010101000$/,
  #   :sat_error_code,"NOM10",
  #   :sat_error_message,"El atributo Comprobante.Receptor.Rfc registra el RFC genérico XAXX010101000, por lo que en el atributo Nomina12:Receptor:Curp, debe registrar la CURP del receptor fallecido."},

  # # NOM11-----------------------------------------------------------------------------------------------------
  # field_value: {
  #   :RegimenFiscalReceptor,:path,'//cfdi:Comprobante/cfdi:Receptor/@RegimenFiscalReceptor',
  #   :value,'605',
  #   :sat_error_code,"NOM11",
  #   :sat_error_message,"El atributo Comprobante.Receptor.RegimenFiscalReceptor no tiene el valor =  605."},

  # # NOM12-----------------------------------------------------------------------------------------------------
  # field_value: {
  #   :UsoCFDI,:path,'//cfdi:Comprobante/cfdi:Receptor/@UsoCFDI',
  #   :value,'CN01',
  #   :sat_error_code,"NOM12",
  #   :sat_error_message,"El atributo Comprobante.Receptor.UsoCFDI no tiene el valor =  CN01."},

  # # NOM23-----------------------------------------------------------------------------------------------------
  # validate_item_presence: {
  #   :objetoImp, '//cfdi:Comprobante/cfdi:Conceptos/cfdi:Concepto[@ObjetoImp = "01"]',
  #   :system_message, ~s(El atributo Comprobante.Conceptos.Concepto.ObjetoImp, se debe registrar la clave "01".),
  #   :sat_error_code, ~s(NOM23),
  #   :sat_error_message, ~s(El atributo Comprobante.Conceptos.Concepto.ObjetoImp, se debe registrar la clave "01".)},

  # # NOM25-----------------------------------------------------------------------------------------------------
  # validate_item_absence: {
  #   :ACuentaTerceros, '//cfdi:Comprobante/cfdi:Conceptos/cfdi:Concepto/cfdi:ACuentaTerceros',
  #   :system_message, ~s(El nodo Comprobante.Conceptos.Concepto.ACuentaTerceros, no debe existir.),
  #   :sat_error_code, ~s(NOM25),
  #   :sat_error_message, ~s(El nodo Comprobante.Conceptos.Concepto.ACuentaTerceros, no debe existir.)},

  # # NOM26-----------------------------------------------------------------------------------------------------
  # validate_item_absence: {
  #   :InformacionAduanera, '//cfdi:Comprobante/cfdi:Conceptos/cfdi:Concepto/cfdi:InformacionAduanera',
  #   :system_message, ~s(El nodo Comprobante.Conceptos.Concepto.InformacionAduanera, no debe existir.),
  #   :sat_error_code, ~s(NOM26),
  #   :sat_error_message, ~s(El nodo Comprobante.Conceptos.Concepto.InformacionAduanera, no debe existir.)},

  # # NOM27-----------------------------------------------------------------------------------------------------
  # validate_item_absence: {
  #   :CuentaPredial, '//cfdi:Comprobante/cfdi:Conceptos/cfdi:Concepto/cfdi:CuentaPredial',
  #   :system_message, ~s(El nodo Comprobante.Conceptos.Concepto.CuentaPredial, no debe existir.),
  #   :sat_error_code, ~s(NOM27),
  #   :sat_error_message, ~s(El nodo Comprobante.Conceptos.Concepto.CuentaPredial, no debe existir.)},

  # # NOM28-----------------------------------------------------------------------------------------------------
  # validate_item_absence: {
  #   :ComplementoConcepto, '//cfdi:Comprobante/cfdi:Conceptos/cfdi:Concepto/cfdi:ComplementoConcepto',
  #   :system_message, ~s(El nodo Comprobante.Conceptos.Concepto.ComplementoConcepto, no debe existir.),
  #   :sat_error_code, ~s(NOM28),
  #   :sat_error_message, ~s(El nodo Comprobante.Conceptos.Concepto.ComplementoConcepto, no debe existir.)},

  # #NOM29-----------------------------------------------------------------------------------------------------
  # validate_item_absence: {
  #   :Parte, '//cfdi:Comprobante/cfdi:Conceptos/cfdi:Concepto/cfdi:Parte',
  #   :system_message, ~s(El nodo Comprobante.Conceptos.Concepto.Parte, no debe existir.),
  #   :sat_error_code, ~s(NOM29),
  #   :sat_error_message, ~s(El nodo Comprobante.Conceptos.Concepto.Parte, no debe existir.)},

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
