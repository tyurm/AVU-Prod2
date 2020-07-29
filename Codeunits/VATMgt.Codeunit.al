codeunit 82005 "AVU VAT Mgt."
{
    trigger OnRun()
    begin

    end;

    var
        GLAcc: Record "G/L Account";
        VATEntry: Record "VAT Entry";
        Selection: Option Open,Closed,"Open and Closed";
        PeriodSelection: Option "Before and Within Period","Within Period";
        PrintInIntegers: Boolean;
        Amount: Decimal;
        RowNo: array[6] of Code[10];
        ErrorText: Text[80];
        i: Integer;
        UseAmtsInAddCurr: Boolean;
        UseAmtsInVATAddCurr: Boolean;
        EndDate: Date;
        StartDate: Date;
        EndDateReq: Date;
        ErrAccountTotaling: Label '"Show Amount in VAT Add. Currency" cannot be used with "Account Totaling" lines';

    procedure CalcLineTotal(VATStmtLine2: Record "VAT Statement Line"; var TotalAmount: Decimal; var TotalEmpty: Decimal; var TotalBase: Decimal; var TotalUnrealizedAmount: Decimal; var TotalUnrealizedBase: Decimal; Level: Integer): Boolean
    begin
        if Level = 0 then begin
            TotalAmount := 0;
            TotalEmpty := 0;
            TotalBase := 0;
            TotalUnrealizedAmount := 0;
            TotalUnrealizedBase := 0;
        end;
        case VATStmtLine2.Type of
            VATStmtLine2.Type::"Account Totaling":
                begin
                    if UseAmtsInVATAddCurr then
                        Error(ErrAccountTotaling);
                    GLAcc.SetFilter("No.", VATStmtLine2."Account Totaling");
                    if EndDateReq = 0D then
                        EndDate := 99991231D
                    else
                        EndDate := EndDateReq;
                    if PeriodSelection = PeriodSelection::"Before and Within Period" then
                        GLAcc.SetRange("Date Filter", 0D, EndDate)
                    else
                        GLAcc.SetRange("Date Filter", StartDate, EndDate);
                    Amount := 0;
                    if GLAcc.FindSet and (VATStmtLine2."Account Totaling" <> '') then
                        repeat
                            GLAcc.CalcFields("Net Change", "Additional-Currency Net Change");
                            Amount := ConditionalAdd(Amount, GLAcc."Net Change", GLAcc."Additional-Currency Net Change", 0);
                        until GLAcc.Next = 0;
                    CalcTotalAmount(VATStmtLine2, TotalAmount, TotalEmpty, TotalBase, TotalUnrealizedAmount, TotalUnrealizedBase);
                end;
            VATStmtLine2.Type::"VAT Entry Totaling":
                begin
                    VATEntry.Reset;
                    VATEntry.SetCurrentKey(
                      Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group",
                      "Tax Jurisdiction Code", "Use Tax", "Posting Date");
                    VATEntry.SetRange(Type, VATStmtLine2."Gen. Posting Type");
                    VATEntry.SetRange("VAT Bus. Posting Group", VATStmtLine2."VAT Bus. Posting Group");
                    VATEntry.SetRange("VAT Prod. Posting Group", VATStmtLine2."VAT Prod. Posting Group");
                    VATEntry.SetRange("Tax Jurisdiction Code", VATStmtLine2."Tax Jurisdiction Code");
                    VATEntry.SetRange("Use Tax", VATStmtLine2."Use Tax");
                    if (EndDateReq <> 0D) or (StartDate <> 0D) then
                        if PeriodSelection = PeriodSelection::"Before and Within Period" then
                            VATEntry.SetRange("Posting Date", 0D, EndDate)
                        else
                            VATEntry.SetRange("Posting Date", StartDate, EndDate);
                    case Selection of
                        Selection::Open:
                            VATEntry.SetRange(Closed, false);
                        Selection::Closed:
                            VATEntry.SetRange(Closed, true);
                        else
                            VATEntry.SetRange(Closed);
                    end;
                    case VATStmtLine2."Amount Type" of
                        VATStmtLine2."Amount Type"::Amount:
                            begin
                                VATEntry.CalcSums(Amount, "Additional-Currency Amount", "AVU Add. VAT Amount");
                                Amount := ConditionalAdd(0, VATEntry.Amount, VATEntry."Additional-Currency Amount", VATEntry."AVU Add. VAT Amount");
                            end;
                        VATStmtLine2."Amount Type"::Base:
                            begin
                                VATEntry.CalcSums(Base, "Additional-Currency Base", "AVU Add. VAT Base Amount");
                                Amount := ConditionalAdd(0, VATEntry.Base, VATEntry."Additional-Currency Base", VATEntry."AVU Add. VAT Base Amount");
                            end;
                        VATStmtLine2."Amount Type"::"Unrealized Amount":
                            begin
                                VATEntry.CalcSums("Unrealized Amount", "Add.-Currency Unrealized Amt.");
                                Amount := ConditionalAdd(0, VATEntry."Unrealized Amount", VATEntry."Add.-Currency Unrealized Amt.", 0);
                            end;
                        VATStmtLine2."Amount Type"::"Unrealized Base":
                            begin
                                VATEntry.CalcSums("Unrealized Base", "Add.-Currency Unrealized Base");
                                Amount := ConditionalAdd(0, VATEntry."Unrealized Base", VATEntry."Add.-Currency Unrealized Base", 0);
                            end;
                        else
                            VATStmtLine2.TestField("Amount Type");
                    end;
                    CalcTotalAmount(VATStmtLine2, TotalAmount, TotalEmpty, TotalBase, TotalUnrealizedAmount, TotalUnrealizedBase);
                end;
            VATStmtLine2.Type::"Row Totaling":
                begin
                    if Level >= ArrayLen(RowNo) then
                        exit(false);
                    Level := Level + 1;
                    RowNo[Level] := VATStmtLine2."Row No.";

                    if VATStmtLine2."Row Totaling" = '' then
                        exit(true);
                    VATStmtLine2.SetRange("Statement Template Name", VATStmtLine2."Statement Template Name");
                    VATStmtLine2.SetRange("Statement Name", VATStmtLine2."Statement Name");
                    VATStmtLine2.SetFilter("Row No.", VATStmtLine2."Row Totaling");
                    if VATStmtLine2.FindSet then
                        repeat
                            if not CalcLineTotal(
                                VATStmtLine2, TotalAmount, TotalEmpty, TotalBase,
                                TotalUnrealizedAmount, TotalUnrealizedBase, Level)
                            then begin
                                if Level > 1 then
                                    exit(false);
                                for i := 1 to ArrayLen(RowNo) do
                                    ErrorText := ErrorText + RowNo[i] + ' => ';
                                ErrorText := ErrorText + '...';
                                VATStmtLine2.FieldError("Row No.", ErrorText);
                            end;
                        until VATStmtLine2.Next = 0;
                end;
            VATStmtLine2.Type::Description:
                ;
        end;

        exit(true);
    end;

    local procedure CalcTotalAmount(VATStmtLine2: Record "VAT Statement Line"; var TotalAmount: Decimal; var TotalEmpty: Decimal; var TotalBase: Decimal; var TotalUnrealizedAmount: Decimal; var TotalUnrealizedBase: Decimal)
    begin
        if VATStmtLine2."Calculate with" = 1 then
            Amount := -Amount;
        if PrintInIntegers and VATStmtLine2.Print then
            Amount := Round(Amount, 1, '<');

        case VATStmtLine2."Amount Type" of
            VATStmtLine2."Amount Type"::" ":
                TotalEmpty := TotalEmpty + Amount;
            VATStmtLine2."Amount Type"::Base:
                TotalBase := TotalBase + Amount;
            VATStmtLine2."Amount Type"::Amount:
                TotalAmount := TotalAmount + Amount;
            VATStmtLine2."Amount Type"::"Unrealized Amount":
                TotalUnrealizedAmount := TotalUnrealizedAmount + Amount;
            VATStmtLine2."Amount Type"::"Unrealized Base":
                TotalUnrealizedBase := TotalUnrealizedBase + Amount;
        end;
    end;

    procedure InitializeRequest(var NewVATStatementName: Record "VAT Statement Name"; var NewVATStatementLine: Record "VAT Statement Line"; NewSelection: Option Open,Closed,"Open and Closed"; NewPeriodSelection: Option "Before and Within Period","Within Period"; NewPrintInIntegers: Boolean; NewUseAmtsInAddCurr: Boolean; NewUseAmtsInVATAddCurr: Boolean)
    begin
        //"VAT Statement Name".Copy(NewVATStatementName);
        //"VAT Statement Line".Copy(NewVATStatementLine);
        Selection := NewSelection;
        PeriodSelection := NewPeriodSelection;
        PrintInIntegers := NewPrintInIntegers;
        UseAmtsInAddCurr := NewUseAmtsInAddCurr;
        UseAmtsInVATAddCurr := NewUseAmtsInVATAddCurr;
        if NewVATStatementLine.GetFilter("Date Filter") <> '' then begin
            StartDate := NewVATStatementLine.GetRangeMin("Date Filter");
            EndDateReq := NewVATStatementLine.GetRangeMax("Date Filter");
            EndDate := EndDateReq;
        end else begin
            StartDate := 0D;
            EndDateReq := 0D;
            EndDate := 99991231D
        end;
    end;

    procedure ConditionalAdd(Amount: Decimal; AmountToAdd: Decimal; AddCurrAmountToAdd: Decimal; AddVATCurrAmountToAdd: Decimal): Decimal
    begin
        if UseAmtsInAddCurr then
            exit(Amount + AddCurrAmountToAdd);

        if UseAmtsInVATAddCurr then
            exit(Amount + AddVATCurrAmountToAdd);

        exit(Amount + AmountToAdd);
    end;


}