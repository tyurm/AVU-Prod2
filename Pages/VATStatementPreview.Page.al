page 82051 "AVU VAT Statement Preview"
{
    Caption = 'VAT Statement Preview';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPlus;
    SaveValues = true;
    SourceTable = "VAT Statement Name";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Selection; Selection)
                {
                    ApplicationArea = VAT;
                    Caption = 'Include VAT entries';
                    OptionCaption = 'Open,Closed,Open and Closed';
                    ToolTip = 'Specifies that VAT entries are included in the VAT Statement Preview window. This only works for lines of type VAT Entry Totaling. It does not work for lines of type Account Totaling.';

                    trigger OnValidate()
                    begin
                        if Selection = Selection::"Open and Closed" then
                            OpenandClosedSelectionOnValida;
                        if Selection = Selection::Closed then
                            ClosedSelectionOnValidate;
                        if Selection = Selection::Open then
                            OpenSelectionOnValidate;
                    end;
                }
                field(PeriodSelection; PeriodSelection)
                {
                    ApplicationArea = VAT;
                    Caption = 'Include VAT entries';
                    OptionCaption = 'Before and Within Period,Within Period';
                    ToolTip = 'Specifies that VAT entries are included in the VAT Statement Preview window. This only works for lines of type VAT Entry Totaling. It does not work for lines of type Account Totaling.';

                    trigger OnValidate()
                    begin
                        if PeriodSelection = PeriodSelection::"Before and Within Period" then
                            BeforeandWithinPeriodSelection;
                        if PeriodSelection = PeriodSelection::"Within Period" then
                            WithinPeriodPeriodSelectionOnV;
                    end;
                }
                field(UseAmtsInAddCurr; UseAmtsInAddCurrStd)
                {
                    ApplicationArea = VAT;
                    Caption = 'Show Amounts in Add. Reporting Currency';
                    MultiLine = true;
                    ToolTip = 'Specifies that the VAT Statement Preview window shows amounts in the additional reporting currency.';
                    Visible = false;
                    trigger OnValidate()
                    begin
                        UseAmtsInVATAddCurr := false;
                        UseAmtsInAddCurrOnPush;
                    end;
                }
                field(UseAmtsInVATAddCurr; UseAmtsInVATAddCurr)
                {
                    ApplicationArea = VAT;
                    Caption = 'Show Amounts in VAT Add. Reporting Currency';
                    MultiLine = true;
                    ToolTip = 'Specifies that the VAT Statement Preview window shows amounts in the VAT additional reporting currency.';

                    trigger OnValidate()
                    var
                        VATStatementLine: record "VAT Statement Line";
                        ErrAccountTotaling: Label '"Show Amount in VAT Add. Currency" cannot be used with "Account Totaling" lines';
                    begin
                        if UseAmtsInVATAddCurr then begin
                            VATStatementLine.SetRange("Statement Template Name", "Statement Template Name");
                            VATStatementLine.SetRange("Statement Name", Name);
                            VATStatementLine.SetRange(type, VATStatementLine.type::"Account Totaling");
                            if not VATStatementLine.IsEmpty then
                                error(ErrAccountTotaling);
                        end;
                        UseAmtsInAddCurrStd := false;
                        UseAmtsInAddCurrOnPush;
                    end;
                }
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = VAT;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';

                    trigger OnValidate()
                    var
                        FilterTokens: Codeunit "Filter Tokens";
                    begin
                        FilterTokens.MakeDateFilter(DateFilter);
                        SetFilter("Date Filter", DateFilter);
                        CurrPage.Update;
                    end;
                }
            }
            part(VATStatementLineSubForm; "AVU VAT Statement Preview Line")
            {
                ApplicationArea = VAT;
                SubPageLink = "Statement Template Name" = FIELD("Statement Template Name"),
                              "Statement Name" = FIELD(Name);
                SubPageView = SORTING("Statement Template Name", "Statement Name", "Line No.");
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        UpdateSubForm;
    end;

    trigger OnOpenPage()
    begin
        DateFilter := '';
        UpdateSubForm;
    end;

    var
        Selection: Option Open,Closed,"Open and Closed";
        PeriodSelection: Option "Before and Within Period","Within Period";
        UseAmtsInAddCurrStd: Boolean;
        UseAmtsInVATAddCurr: Boolean;
        DateFilter: Text[30];

    procedure UpdateSubForm()
    begin
        CurrPage.VATStatementLineSubForm.PAGE.UpdateForm(Rec, Selection, PeriodSelection, UseAmtsInAddCurrStd, UseAmtsInVATAddCurr);
    end;

    local procedure OpenandClosedSelectionOnPush()
    begin
        UpdateSubForm;
    end;

    local procedure ClosedSelectionOnPush()
    begin
        UpdateSubForm;
    end;

    local procedure OpenSelectionOnPush()
    begin
        UpdateSubForm;
    end;

    local procedure BeforeandWithinPeriodSelOnPush()
    begin
        UpdateSubForm;
    end;

    local procedure WithinPeriodPeriodSelectOnPush()
    begin
        UpdateSubForm;
    end;

    local procedure UseAmtsInAddCurrOnPush()
    begin
        UpdateSubForm;
    end;

    local procedure OpenSelectionOnValidate()
    begin
        OpenSelectionOnPush;
    end;

    local procedure ClosedSelectionOnValidate()
    begin
        ClosedSelectionOnPush;
    end;

    local procedure OpenandClosedSelectionOnValida()
    begin
        OpenandClosedSelectionOnPush;
    end;

    local procedure WithinPeriodPeriodSelectionOnV()
    begin
        WithinPeriodPeriodSelectOnPush;
    end;

    local procedure BeforeandWithinPeriodSelection()
    begin
        BeforeandWithinPeriodSelOnPush;
    end;
}

