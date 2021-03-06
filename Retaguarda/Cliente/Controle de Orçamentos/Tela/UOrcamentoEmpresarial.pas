{ *******************************************************************************
Title: T2Ti ERP
Description: Janela Or�ameto Empresarial

The MIT License

Copyright: Copyright (C) 2015 T2Ti.COM

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

The author may be contacted at:
t2ti.com@gmail.com</p>

@author Albert Eije
@version 2.0
******************************************************************************* }
unit UOrcamentoEmpresarial;

{$MODE Delphi}

interface

uses
  BrookHTTPClient, BrookFCLHTTPClientBroker, BrookHTTPUtils, BrookUtils, FPJson, ZDataset,
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UTelaCadastro, Menus, StdCtrls, ExtCtrls, Buttons, Grids, DBGrids,
  ComCtrls, LabeledCtrls, rxdbgrid, rxtoolbar, DBCtrls, StrUtils, StdActns, ShellApi,
  Math, Constantes, CheckLst, ActnList, ToolWin, db, BufDataset, Biblioteca,
  ULookup, VO, OrcamentoEmpresarialVO, OrcamentoEmpresarialController, DateUtils;

  type

  { TFOrcamentoEmpresarial }

  TFOrcamentoEmpresarial = class(TFTelaCadastro)
    CDSOrcamentoDetalhe: TBufDataset;
    PanelParcelas: TPanel;
    PanelMestre: TPanel;
    EditIdOrcamentoPeriodo: TLabeledCalcEdit;
    EditOrcamentoPeriodo: TLabeledEdit;
    EditNome: TLabeledEdit;
    EditDataBase: TLabeledDateEdit;
    EditNumeroPeriodos: TLabeledCalcEdit;
    EditDataInicial: TLabeledDateEdit;
    PageControlItens: TPageControl;
    tsItens: TTabSheet;
    PanelItens: TPanel;
    GridOrcamentoDetalhe: TRxDbGrid;
    ActionToolBarEdits: TToolPanel;
    ActionManager: TActionList;
    ActionGerarOrcamentoEmpresarial: TAction;
    ActionPegarRealizado: TAction;
    ActionCalcularVariacao: TAction;
    DSOrcamentoDetalhe: TDataSource;
    MemoDescricao: TLabeledMemo;
    EditOrcamentoPeriodoCodigo: TLabeledEdit;
    procedure FormCreate(Sender: TObject);
    procedure GridDblClick(Sender: TObject);
    procedure GridOrcamentoDetalheKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ActionGerarOrcamentoEmpresarialExecute(Sender: TObject);
    procedure ActionPegarRealizadoExecute(Sender: TObject);
    procedure ActionCalcularVariacaoExecute(Sender: TObject);
    procedure CDSOrcamentoDetalheAfterPost(DataSet: TDataSet);
    procedure EditIdOrcamentoPeriodoKeyUp(Sender: TObject; var Key: Word;  Shift: TShiftState);

    procedure BotaoConsultarClick(Sender: TObject);
    procedure BotaoSalvarClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure GridParaEdits; override;
    procedure LimparCampos; override;

    // Controles CRUD
    function DoInserir: Boolean; override;
    function DoEditar: Boolean; override;
    function DoExcluir: Boolean; override;
    function DoSalvar: Boolean; override;

    procedure ConfigurarLayoutTela;
  end;

var
  FOrcamentoEmpresarial: TFOrcamentoEmpresarial;

implementation

uses UDataModule, OrcamentoDetalheController,
  OrcamentoDetalheVO, NaturezaFinanceiraController, NaturezaFinanceiraVO,
  ViewFinTotalRecebimentosDiaController, ViewFinTotalPagamentosDiaController,
  ViewFinTotalRecebimentosDiaVO, ViewFinTotalPagamentosDiaVO,
  OrcamentoPeriodoVO, OrcamentoPeriodoController,
  PlanoNaturezaFinanceiraVO, PlanoNaturezaFinanceiraController;
{$R *.lfm}

{$REGION 'Infra'}
procedure TFOrcamentoEmpresarial.BotaoConsultarClick(Sender: TObject);
var
  RetornoConsulta: TZQuery;
  ListaCampos: TStringList;
  i: integer;
begin
  inherited;

  if Sessao.Camadas = 2 then
  begin
    Filtro := MontaFiltro;

    CDSGrid.Close;
    CDSGrid.Open;
    ConfiguraGridFromVO(Grid, ClasseObjetoGridVO);

    ListaCampos  := TStringList.Create;
    RetornoConsulta := TOrcamentoEmpresarialController.Consulta(Filtro, IntToStr(Pagina));
    RetornoConsulta.Active := True;

    RetornoConsulta.GetFieldNames(ListaCampos);

    RetornoConsulta.First;
    while not RetornoConsulta.EOF do
    begin
      CDSGrid.Append;
      for i := 0 to ListaCampos.Count - 1 do
      begin
        CDSGrid.FieldByName(ListaCampos[i]).Value := RetornoConsulta.FieldByName(ListaCampos[i]).Value;
      end;
      CDSGrid.Post;
      RetornoConsulta.Next;
    end;
  end;
end;

procedure TFOrcamentoEmpresarial.BotaoSalvarClick(Sender: TObject);
begin
  inherited;
  BotaoConsultarClick(Sender);
end;

procedure TFOrcamentoEmpresarial.FormCreate(Sender: TObject);
begin
  ClasseObjetoGridVO := TOrcamentoEmpresarialVO;
  ObjetoController := TOrcamentoEmpresarialController.Create;

  inherited;

  ConfiguraCDSFromVO(CDSOrcamentoDetalhe, TOrcamentoDetalheVO);
  ConfiguraGridFromVO(GridOrcamentoDetalhe, TOrcamentoDetalheVO);
end;

procedure TFOrcamentoEmpresarial.LimparCampos;
begin
  inherited;
  CDSOrcamentoDetalhe.Close;
  CDSOrcamentoDetalhe.Open;
end;

procedure TFOrcamentoEmpresarial.ConfigurarLayoutTela;
begin
  PanelEdits.Enabled := True;

  if StatusTela = stNavegandoEdits then
  begin
    PanelMestre.Enabled := False;
    PanelItens.Enabled := True;
    ActionGerarOrcamentoEmpresarial.Enabled := False;
    ActionPegarRealizado.Enabled := False;
    ActionCalcularVariacao.Enabled := False;
  end
  else
  begin
    PanelMestre.Enabled := True;
    PanelItens.Enabled := True;
    ActionGerarOrcamentoEmpresarial.Enabled := True;
    ActionPegarRealizado.Enabled := True;
    ActionCalcularVariacao.Enabled := True
  end;
end;
{$ENDREGION}

{$REGION 'Controles CRUD'}
function TFOrcamentoEmpresarial.DoInserir: Boolean;
begin
  Result := inherited DoInserir;

  ConfigurarLayoutTela;
  if Result then
  begin
    EditIdOrcamentoPeriodo.SetFocus;
  end;
end;

function TFOrcamentoEmpresarial.DoEditar: Boolean;
begin
  Result := inherited DoEditar;

  ConfigurarLayoutTela;
  if Result then
  begin
    EditIdOrcamentoPeriodo.SetFocus;
  end;
end;

function TFOrcamentoEmpresarial.DoExcluir: Boolean;
begin
  if inherited DoExcluir then
  begin
    try
      Result := TOrcamentoEmpresarialController.Exclui(IdRegistroSelecionado);
    except
      Result := False;
    end;
  end
  else
  begin
    Result := False;
  end;

  if Result then
    BotaoConsultar.Click;
end;

function TFOrcamentoEmpresarial.DoSalvar: Boolean;
var
  OrcamentoDetalhe: TOrcamentoDetalheVO;
begin
  Result := inherited DoSalvar;

  if Result then
  begin
    try
      if not Assigned(ObjetoVO) then
        ObjetoVO := TOrcamentoEmpresarialVO.Create;

      TOrcamentoEmpresarialVO(ObjetoVO).IdOrcamentoPeriodo := EditIdOrcamentoPeriodo.AsInteger;
      TOrcamentoEmpresarialVO(ObjetoVO).OrcamentoPeriodoNome := EditOrcamentoPeriodo.Text;
      TOrcamentoEmpresarialVO(ObjetoVO).OrcamentoPeriodoCodigo := EditOrcamentoPeriodoCodigo.Text;
      TOrcamentoEmpresarialVO(ObjetoVO).Nome := EditNome.Text;
      TOrcamentoEmpresarialVO(ObjetoVO).Descricao := MemoDescricao.Text;
      TOrcamentoEmpresarialVO(ObjetoVO).DataInicial := EditDataInicial.Date;
      TOrcamentoEmpresarialVO(ObjetoVO).NumeroPeriodos := EditNumeroPeriodos.AsInteger;
      TOrcamentoEmpresarialVO(ObjetoVO).DataBase := EditDataBase.Date;

      if StatusTela = stEditando then
        TOrcamentoEmpresarialVO(ObjetoVO).Id := IdRegistroSelecionado;

      // Detalhes do or�amento
      CDSOrcamentoDetalhe.DisableControls;
      CDSOrcamentoDetalhe.First;
      while not CDSOrcamentoDetalhe.Eof do
      begin
          OrcamentoDetalhe := TOrcamentoDetalheVO.Create;
          OrcamentoDetalhe.Id := CDSOrcamentoDetalhe.FieldByName('ID').AsInteger;
          OrcamentoDetalhe.IdNaturezaFinanceira := CDSOrcamentoDetalhe.FieldByName('ID_NATUREZA_FINANCEIRA').AsInteger;
          OrcamentoDetalhe.IdOrcamentoEmpresarial := CDSOrcamentoDetalhe.FieldByName('ID_ORCAMENTO_EMPRESARIAL').AsInteger;
          OrcamentoDetalhe.Periodo := CDSOrcamentoDetalhe.FieldByName('PERIODO').AsString;
          OrcamentoDetalhe.ValorOrcado := CDSOrcamentoDetalhe.FieldByName('VALOR_ORCADO').AsFloat;
          OrcamentoDetalhe.ValorRealizado := CDSOrcamentoDetalhe.FieldByName('VALOR_REALIZADO').AsFloat;
          OrcamentoDetalhe.TaxaVariacao := CDSOrcamentoDetalhe.FieldByName('TAXA_VARIACAO').AsFloat;
          OrcamentoDetalhe.ValorVariacao := CDSOrcamentoDetalhe.FieldByName('VALOR_VARIACAO').AsFloat;
          TOrcamentoEmpresarialVO(ObjetoVO).ListaOrcamentoDetalheVO.Add(OrcamentoDetalhe);
        CDSOrcamentoDetalhe.Next;
      end;
      CDSOrcamentoDetalhe.EnableControls;

      if StatusTela = stInserindo then
      begin
        TOrcamentoEmpresarialController.Insere(TOrcamentoEmpresarialVO(ObjetoVO));
      end
      else if StatusTela = stEditando then
      begin
        /// EXERCICIO: Verifique se tem como serializar as listas junto com o objeto para realizar a compara��o
        //if TOrcamentoEmpresarialVO(ObjetoVO).ToJSONString <> StringObjetoOld then
        //begin
          TOrcamentoEmpresarialController.Altera(TOrcamentoEmpresarialVO(ObjetoVO));
        //end
        //else
        //Application.MessageBox('Nenhum dado foi alterado.', 'Mensagem do Sistema', MB_OK + MB_ICONINFORMATION);
      end;
    except
      Result := False;
    end;
  end;
end;
{$ENDREGION}

{$REGION 'Campos Transientes'}
procedure TFOrcamentoEmpresarial.EditIdOrcamentoPeriodoKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  Filtro: String;
  OrcamentoPeriodoVO: TOrcamentoPeriodoVO;
begin
  if Key = VK_F1 then
  begin
    if EditIdOrcamentoPeriodo.Value <> 0 then
      Filtro := 'ID = ' + EditIdOrcamentoPeriodo.Text
    else
      Filtro := 'ID=0';

    try
      EditIdOrcamentoPeriodo.Clear;
      EditOrcamentoPeriodo.Clear;

      OrcamentoPeriodoVO := TOrcamentoPeriodoController.ConsultaObjeto(Filtro);
      if Assigned(OrcamentoPeriodoVO) then
      begin
        EditOrcamentoPeriodo.Text := OrcamentoPeriodoVO.Nome;
        EditOrcamentoPeriodoCodigo.Text := OrcamentoPeriodoVO.Periodo;
      end
      else
      begin
        Exit;
        EditNome.SetFocus;
      end;
    finally
    end;
  end;
end;
{$ENDREGION}

{$REGION 'Controle de Grid'}
procedure TFOrcamentoEmpresarial.GridDblClick(Sender: TObject);
begin
  inherited;
  ConfigurarLayoutTela;
end;

procedure TFOrcamentoEmpresarial.GridParaEdits;
var
  IdCabecalho: String;
  Current: TOrcamentoDetalheVO;
  i: Integer;
begin
  inherited;

  if not CDSGrid.IsEmpty then
  begin
    IdCabecalho := IntToStr(IdRegistroSelecionado);
    ObjetoVO := TOrcamentoEmpresarialController.ConsultaObjeto('ID=' + IdCabecalho);
  end;

  if Assigned(ObjetoVO) then
  begin
    EditIdOrcamentoPeriodo.AsInteger := TOrcamentoEmpresarialVO(ObjetoVO).IdOrcamentoPeriodo;
    EditOrcamentoPeriodo.Text := TOrcamentoEmpresarialVO(ObjetoVO).OrcamentoPeriodoNome;
    EditOrcamentoPeriodoCodigo.Text := TOrcamentoEmpresarialVO(ObjetoVO).OrcamentoPeriodoCodigo;
    EditNome.Text := TOrcamentoEmpresarialVO(ObjetoVO).Nome;
    MemoDescricao.Text := TOrcamentoEmpresarialVO(ObjetoVO).Descricao;
    EditDataInicial.Date := TOrcamentoEmpresarialVO(ObjetoVO).DataInicial;
    EditNumeroPeriodos.AsInteger := TOrcamentoEmpresarialVO(ObjetoVO).NumeroPeriodos;
    EditDataBase.Date := TOrcamentoEmpresarialVO(ObjetoVO).DataBase;

    // Detalhes do or�amento
    for i := 0 to TOrcamentoEmpresarialVO(ObjetoVO).ListaOrcamentoDetalheVO.Count -1 do
    begin
      Current := TOrcamentoEmpresarialVO(ObjetoVO).ListaOrcamentoDetalheVO[i];

      CDSOrcamentoDetalhe.Append;
      CDSOrcamentoDetalhe.FieldByName('ID').AsInteger := Current.Id;
      CDSOrcamentoDetalhe.FieldByName('ID_ORCAMENTO_EMPRESARIAL').AsInteger := Current.IdOrcamentoEmpresarial;
      CDSOrcamentoDetalhe.FieldByName('ID_NATUREZA_FINANCEIRA').AsInteger := Current.IdNaturezaFinanceira;
      //CDSOrcamentoDetalhe.FieldByName('NATUREZA_FINANCEIRACLASSIFICACAO').AsString := Current.NaturezaFinanceiraVO.Classificacao; ;
      //CDSOrcamentoDetalhe.FieldByName('NATUREZA_FINANCEIRADESCRICAO').AsString := Current.NaturezaFinanceiraVO.Descricao;
      CDSOrcamentoDetalhe.FieldByName('PERIODO').AsString := Current.Periodo;
      CDSOrcamentoDetalhe.FieldByName('VALOR_ORCADO').AsFloat := Current.ValorOrcado;
      CDSOrcamentoDetalhe.FieldByName('VALOR_REALIZADO').AsFloat := Current.ValorRealizado;
      CDSOrcamentoDetalhe.FieldByName('TAXA_VARIACAO').AsFloat := Current.TaxaVariacao;
      CDSOrcamentoDetalhe.FieldByName('VALOR_VARIACAO').AsFloat := Current.ValorVariacao;
      CDSOrcamentoDetalhe.Post;
    end;

    // Serializa o objeto para consultar posteriormente se houve altera��es
    FormatSettings.DecimalSeparator := '.';
    StringObjetoOld := ObjetoVO.ToJSONString;
    FormatSettings.DecimalSeparator := ',';
  end;
  ConfigurarLayoutTela;
end;

procedure TFOrcamentoEmpresarial.GridOrcamentoDetalheKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  If Key = VK_RETURN then
    GridOrcamentoDetalhe.SelectedIndex := GridOrcamentoDetalhe.SelectedIndex + 1;
end;

procedure TFOrcamentoEmpresarial.CDSOrcamentoDetalheAfterPost(DataSet: TDataSet);
begin
  if CDSOrcamentoDetalhe.FieldByName('NATUREZA_FINANCEIRACLASSIFICACAO').AsString = '' then
    CDSOrcamentoDetalhe.Delete;
end;
{$ENDREGION}

{$REGION 'Actions'}
procedure TFOrcamentoEmpresarial.ActionGerarOrcamentoEmpresarialExecute(Sender: TObject);
var
  PlanoNaturezaFinanceira: TPlanoNaturezaFinanceiraVO;
  i, ContadorPeriodo: Integer;
  Filtro: String;
begin
  /// EXERCICIO: SE J� EXISTIREM DADOS NO BANCO E VOC� CLICAR NO BOT�O "GERAR OR�AMENTO" O QUE VAI OCORRER? FA�A V�RIOS TESTES E CORRIJA O QUE FOR PRECISO

  CDSOrcamentoDetalhe.Close;
  CDSOrcamentoDetalhe.Open;
  try

    /// EXERCICIO: implemente a busca pelo plano da natureza financeira usando a janela de lookup
    Filtro := 'ID=1';
    PlanoNaturezaFinanceira := TPlanoNaturezaFinanceiraController.ConsultaObjeto(Filtro);
    if Assigned(PlanoNaturezaFinanceira) then
    begin
      Filtro := 'ID_PLANO_NATUREZA_FINANCEIRA = ' + QuotedStr(IntToStr(PlanoNaturezaFinanceira.Id));
      CDSConsultaGenerica := TNaturezaFinanceiraController.Consulta(Filtro, '0');
      CDSConsultaGenerica.Active := True;

      ContadorPeriodo := 0;

      // 01=Di�rio | 02=Semanal | 03=Mensal | 04=Bimestral | 05=Trimestral | 06=Semestral | 07=Anual
      for i := 1 to EditNumeroPeriodos.AsInteger do
      begin

        CDSConsultaGenerica.First;
        while not CDSConsultaGenerica.Eof do
        begin
          CDSOrcamentoDetalhe.Append;
          CDSOrcamentoDetalhe.FieldByName('ID_NATUREZA_FINANCEIRA').AsInteger := CDSConsultaGenerica.FieldByName('ID').AsInteger;
          //CDSOrcamentoDetalhe.FieldByName('NATUREZA_FINANCEIRACLASSIFICACAO').AsString := CDSConsultaGenerica.FieldByName('CLASSIFICACAO').AsString;
          //CDSOrcamentoDetalhe.FieldByName('NATUREZA_FINANCEIRADESCRICAO').AsString := CDSConsultaGenerica.FieldByName('DESCRICAO').AsString;
          CDSOrcamentoDetalhe.FieldByName('VALOR_ORCADO').AsFloat := 0;
          CDSOrcamentoDetalhe.FieldByName('VALOR_REALIZADO').AsFloat := 0;
          CDSOrcamentoDetalhe.FieldByName('TAXA_VARIACAO').AsFloat := 0;
          CDSOrcamentoDetalhe.FieldByName('VALOR_VARIACAO').AsFloat := 0;

          case StrToInt(EditOrcamentoPeriodoCodigo.Text) of
            1: // di�rio
              CDSOrcamentoDetalhe.FieldByName('PERIODO').AsString := DateToStr(EditDataInicial.Date + ContadorPeriodo);
            2: // semanal
              CDSOrcamentoDetalhe.FieldByName('PERIODO').AsString := DateToStr(IncWeek(EditDataInicial.Date, ContadorPeriodo));
            3: // mensal
              CDSOrcamentoDetalhe.FieldByName('PERIODO').AsString := Copy(DateToStr(IncMonth(EditDataInicial.Date, ContadorPeriodo)), 4, 7);
            4: // bimestral
              CDSOrcamentoDetalhe.FieldByName('PERIODO').AsString := Copy(DateToStr(IncMonth(EditDataInicial.Date, ContadorPeriodo * 2)), 4, 7);
            5: // trimestral
              CDSOrcamentoDetalhe.FieldByName('PERIODO').AsString := Copy(DateToStr(IncMonth(EditDataInicial.Date, ContadorPeriodo * 3)), 4, 7);
            6: // semestral
              CDSOrcamentoDetalhe.FieldByName('PERIODO').AsString := Copy(DateToStr(IncMonth(EditDataInicial.Date, ContadorPeriodo * 6)), 4, 7);
            7: // anual
              CDSOrcamentoDetalhe.FieldByName('PERIODO').AsString := Copy(DateToStr(IncYear(EditDataInicial.Date, ContadorPeriodo)), 7, 4);
          end;
          CDSOrcamentoDetalhe.Post;
          CDSConsultaGenerica.Next;
        end;
        Inc(ContadorPeriodo);
      end;
      CDSConsultaGenerica.Close;
      GridOrcamentoDetalhe.SetFocus;
    end;
  finally
  end;
end;

procedure TFOrcamentoEmpresarial.ActionPegarRealizadoExecute(Sender: TObject);
var
  FiltroRecebimento, FiltroPagamento: String;
  DataInicio, DataFim: TDateTime;
  RealizadoPagar, RealizadoReceber: Extended;
begin
  try
    CDSOrcamentoDetalhe.DisableControls;
    CDSOrcamentoDetalhe.First;
    while not CDSOrcamentoDetalhe.Eof do
    begin
      RealizadoPagar := 0;
      RealizadoReceber := 0;

      /// EXERCICIO: O FILTRO N�O EST� LEVANDO EM CONSIDERA��O A NATUREZA FINANCEIRA. CORRIJA ISSO.
      /// EXERCICIO: OBSERVE SE A DATA QUE EST� SENDO MONTADA NO FILTRO EST� DE ACORDO COM O DESEJADO PARA ENCONTRAR OS DADOS PRETENDIDOS

      //Define o filtro
      if EditOrcamentoPeriodoCodigo.Text = '01' then //Di�rio
      begin
        DataInicio := StrToDate(Copy(CDSOrcamentoDetalhe.FieldByName('PERIODO').AsString, 1, 2) +  Copy(EditDataBase.Text, 3, 8));
        FiltroRecebimento := 'DATA_RECEBIMENTO='+QuotedStr(DataParaTexto(DataInicio));
        FiltroPagamento := 'DATA_PAGAMENTO='+QuotedStr(DataParaTexto(DataInicio));
      end
      else if EditOrcamentoPeriodoCodigo.Text = '02' then //Semanal
      begin
        DataInicio := StrToDate(CDSOrcamentoDetalhe.FieldByName('PERIODO').AsString);
        DataFim := StrToDate(CDSOrcamentoDetalhe.FieldByName('PERIODO').AsString) + 6;
        FiltroRecebimento := '(DATA_RECEBIMENTO between '+QuotedStr(DataParaTexto(DataInicio)) + ' and ' + QuotedStr(DataParaTexto(DataFim)) + ')';
        FiltroPagamento := '(DATA_PAGAMENTO between '+QuotedStr(DataParaTexto(DataInicio)) + ' and ' + QuotedStr(DataParaTexto(DataFim)) + ')';
      end
      else if EditOrcamentoPeriodoCodigo.Text = '03' then //Mensal
      begin
        DataInicio := StrToDate('01/'+CDSOrcamentoDetalhe.FieldByName('PERIODO').AsString);
        DataFim := StrToDate('01/'+CDSOrcamentoDetalhe.FieldByName('PERIODO').AsString) + 30;
        FiltroRecebimento := '(DATA_RECEBIMENTO between '+QuotedStr(DataParaTexto(DataInicio)) + ' and ' + QuotedStr(DataParaTexto(DataFim)) + ')';
        FiltroPagamento := '(DATA_PAGAMENTO between '+QuotedStr(DataParaTexto(DataInicio)) + ' and ' + QuotedStr(DataParaTexto(DataFim)) + ')';
      end
      else if EditOrcamentoPeriodoCodigo.Text = '04' then //Bimestral
      begin
        DataInicio := StrToDate('01/'+CDSOrcamentoDetalhe.FieldByName('PERIODO').AsString);
        DataFim := StrToDate('01/'+CDSOrcamentoDetalhe.FieldByName('PERIODO').AsString) + 60;
        FiltroRecebimento := '(DATA_RECEBIMENTO between '+QuotedStr(DataParaTexto(DataInicio)) + ' and ' + QuotedStr(DataParaTexto(DataFim)) + ')';
        FiltroPagamento := '(DATA_PAGAMENTO between '+QuotedStr(DataParaTexto(DataInicio)) + ' and ' + QuotedStr(DataParaTexto(DataFim)) + ')';
      end
      else if EditOrcamentoPeriodoCodigo.Text = '05' then //Trimestral
      begin
        DataInicio := StrToDate('01/'+CDSOrcamentoDetalhe.FieldByName('PERIODO').AsString);
        DataFim := StrToDate('01/'+CDSOrcamentoDetalhe.FieldByName('PERIODO').AsString) + 90;
        FiltroRecebimento := '(DATA_RECEBIMENTO between '+QuotedStr(DataParaTexto(DataInicio)) + ' and ' + QuotedStr(DataParaTexto(DataFim)) + ')';
        FiltroPagamento := '(DATA_PAGAMENTO between '+QuotedStr(DataParaTexto(DataInicio)) + ' and ' + QuotedStr(DataParaTexto(DataFim)) + ')';
      end
      else if EditOrcamentoPeriodoCodigo.Text = '06' then //Semestral
      begin
        DataInicio := StrToDate('01/'+CDSOrcamentoDetalhe.FieldByName('PERIODO').AsString);
        DataFim := StrToDate('01/'+CDSOrcamentoDetalhe.FieldByName('PERIODO').AsString) + 180;
        FiltroRecebimento := '(DATA_RECEBIMENTO between '+QuotedStr(DataParaTexto(DataInicio)) + ' and ' + QuotedStr(DataParaTexto(DataFim)) + ')';
        FiltroPagamento := '(DATA_PAGAMENTO between '+QuotedStr(DataParaTexto(DataInicio)) + ' and ' + QuotedStr(DataParaTexto(DataFim)) + ')';
      end
      else if EditOrcamentoPeriodoCodigo.Text = '07' then //Anual
      begin
        DataInicio := StrToDate('01/01/'+CDSOrcamentoDetalhe.FieldByName('PERIODO').AsString);
        DataFim := StrToDate('31/12/'+CDSOrcamentoDetalhe.FieldByName('PERIODO').AsString);
        FiltroRecebimento := '(DATA_RECEBIMENTO between '+QuotedStr(DataParaTexto(DataInicio)) + ' and ' + QuotedStr(DataParaTexto(DataFim)) + ')';
        FiltroPagamento := '(DATA_PAGAMENTO between '+QuotedStr(DataParaTexto(DataInicio)) + ' and ' + QuotedStr(DataParaTexto(DataFim)) + ')';
      end;

      //Realiza a consulta e pega os valores recebidos
      CDSConsultaGenerica := TViewFinTotalRecebimentosDiaController.Consulta(FiltroRecebimento, '0');
      CDSConsultaGenerica.Active := True;
      CDSConsultaGenerica.First;
      while not CDSConsultaGenerica.Eof do
      begin
        RealizadoReceber := RealizadoReceber + CDSConsultaGenerica.FieldByName('TOTAL').AsFloat;
        CDSConsultaGenerica.Next;
      end;
      CDSConsultaGenerica.Close;

      //Realiza a consulta e pega os valores pagos
      CDSConsultaGenerica := TViewFinTotalPagamentosDiaController.Consulta(FiltroPagamento, '0');
      CDSConsultaGenerica.Active := True;
      CDSConsultaGenerica.First;
      while not CDSConsultaGenerica.Eof do
      begin
        RealizadoPagar := RealizadoPagar + CDSConsultaGenerica.FieldByName('TOTAL').AsFloat;
        CDSConsultaGenerica.Next;
      end;
      CDSConsultaGenerica.Close;

      //Grava os valores
      CDSOrcamentoDetalhe.Edit;
      CDSOrcamentoDetalhe.FieldByName('VALOR_REALIZADO').AsFloat := RealizadoPagar + RealizadoReceber;
      CDSOrcamentoDetalhe.Post;

      CDSOrcamentoDetalhe.Next;
    end;
    CDSOrcamentoDetalhe.First;
    CDSOrcamentoDetalhe.EnableControls;

    GridOrcamentoDetalhe.SetFocus;
  except
    on E: Exception do
      Application.MessageBox(PChar('Ocorreu um erro na consulta do realizado. Informe a mensagem ao Administrador do sistema.' + #13 + #13 + E.Message), 'Erro do sistema', MB_OK + MB_ICONERROR);
  end;
end;

procedure TFOrcamentoEmpresarial.ActionCalcularVariacaoExecute(Sender: TObject);
begin
  try
    CDSOrcamentoDetalhe.DisableControls;
    CDSOrcamentoDetalhe.First;
    while not CDSOrcamentoDetalhe.Eof do
    begin
      if (CDSOrcamentoDetalhe.FieldByName('VALOR_REALIZADO').AsFloat <> 0) and (CDSOrcamentoDetalhe.FieldByName('VALOR_ORCADO').AsFloat <> 0) then
      begin
        CDSOrcamentoDetalhe.Edit;
        CDSOrcamentoDetalhe.FieldByName('VALOR_VARIACAO').AsFloat := CDSOrcamentoDetalhe.FieldByName('VALOR_REALIZADO').AsFloat - CDSOrcamentoDetalhe.FieldByName('VALOR_ORCADO').AsFloat;
        CDSOrcamentoDetalhe.FieldByName('TAXA_VARIACAO').AsFloat := RoundTo(CDSOrcamentoDetalhe.FieldByName('VALOR_VARIACAO').AsFloat / CDSOrcamentoDetalhe.FieldByName('VALOR_ORCADO').AsFloat * 100, -2);
        CDSOrcamentoDetalhe.Post;
      end;
      CDSOrcamentoDetalhe.Next;
    end;
    CDSOrcamentoDetalhe.First;
    CDSOrcamentoDetalhe.EnableControls;
    GridOrcamentoDetalhe.SetFocus;
  except
    on E: Exception do
      Application.MessageBox(PChar('Ocorreu um erro ao calcular a varia��o. Informe a mensagem ao Administrador do sistema.' + #13 + #13 + E.Message), 'Erro do sistema', MB_OK + MB_ICONERROR);
  end;

end;
{$ENDREGION}

end.

