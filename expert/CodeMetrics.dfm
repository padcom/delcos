object FrmCodeMetrics: TFrmCodeMetrics
  Left = 183
  Top = 216
  Width = 771
  Height = 275
  BorderStyle = bsSizeToolWin
  Caption = 'Code metrics'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = True
  Position = poScreenCenter
  OnKeyDown = FormKeyDown
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object LivMetrics: TListView
    Left = 0
    Top = 0
    Width = 763
    Height = 229
    Align = alClient
    Columns = <
      item
        Caption = 'Procedure name'
      end
      item
        Caption = 'Complexity'
      end
      item
        Caption = 'Code lines'
      end
      item
        Caption = 'Statements'
      end
      item
        Caption = 'Column'
      end
      item
        Caption = 'Row'
      end>
    IconOptions.AutoArrange = True
    ReadOnly = True
    RowSelect = True
    SortType = stText
    TabOrder = 0
    ViewStyle = vsReport
    OnColumnClick = LivMetricsColumnClick
    OnCompare = LivMetricsCompare
    OnDblClick = LivMetricsDblClick
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 229
    Width = 763
    Height = 19
    Panels = <>
  end
end
