report 82006 "Update Document Exchange Rate"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;

    dataset
    {
        dataitem(SalesHeader; "Sales Header")
        {
            trigger OnPreDataItem()
            begin
                if not UpdateSales then
                    CurrReport.Break();
                SalesHeader.SetRange("Currency Code", CurrencyCode);
            end;

            trigger OnAfterGetRecord()
            begin
                SalesHeader.SetHideValidationDialog(true);
                //SalesHeader.UpdateCurrencyFactor();
                SalesHeader.Validate("Currency Factor", CurrExchRate.ExchangeRate(SalesHeader."Posting Date", SalesHeader."Currency Code"));
                SalesHeader.Modify(true);
                Commit();
                Counter += 1;
            end;
        }
        dataitem(PurchaseHeader; "Purchase Header")
        {
            trigger OnPreDataItem()
            begin
                if not UpdatePurchase then
                    CurrReport.Break();
                PurchaseHeader.SetRange("Currency Code", CurrencyCode);
            end;

            trigger OnAfterGetRecord()
            begin
                PurchaseHeader.SetHideValidationDialog(true);
                //PurchaseHeader.UpdateCurrencyFactor();
                PurchaseHeader.Validate("Currency Factor", CurrExchRate.ExchangeRate(PurchaseHeader."Posting Date", PurchaseHeader."Currency Code"));
                PurchaseHeader.Modify(true);
                Commit();
                Counter += 1;
            end;
        }
    }
    requestpage
    {
        layout
        {
            area(content)
            {
                group(GroupName)
                {
                    Caption = 'Options';
                    field(UpdateSalesControl; UpdateSales)
                    {
                        Caption = 'Update Sales Documents';
                        ApplicationArea = All;
                    }
                    field(UpdatePurchaseControl; UpdatePurchase)
                    {
                        Caption = 'Update Purchase Documents';
                        ApplicationArea = All;
                    }
                    field(CurrencyCodeControl; CurrencyCode)
                    {
                        Caption = 'Currency Code';
                        ApplicationArea = All;
                        TableRelation = Currency;
                    }
                }
            }
        }
        actions
        {
            area(processing)
            {
            }
        }
    }

    var
        CurrExchRate: Record "Currency Exchange Rate";
        DoneLbl: Label 'Updated %1 document(s).';
        //Factor: Decimal;
        Counter: Integer;
        CurrencyCode: Code[10];
        //PostingDate: Date;
        UpdateSales: Boolean;
        UpdatePurchase: Boolean;


    trigger OnPostReport()
    begin
        Message(DoneLbl, Counter);
    end;
}
