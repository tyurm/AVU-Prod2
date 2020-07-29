table 82050 "AVU Add. VAT Exchange Rate"
{
    Caption = 'Add. VAT  Exchange Rate';
    DataCaptionFields = "Currency Code";
    DrillDownPageID = "AVU Add. VAT Exchange Rates";
    LookupPageID = "AVU Add. VAT Exchange Rates";

    fields
    {
        field(1; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            NotBlank = true;
            TableRelation = Currency;
        }
        field(2; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            NotBlank = true;
        }
        field(3; "Exchange Rate Amount"; Decimal)
        {
            Caption = 'Exchange Rate Amount';
            DecimalPlaces = 1 : 6;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestField("Exchange Rate Amount");
            end;
        }
        field(6; "Relational Exch. Rate Amount"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Relational Exch. Rate Amount';
            DecimalPlaces = 1 : 6;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestField("Relational Exch. Rate Amount");
            end;
        }
    }

    keys
    {
        key(Key1; "Currency Code", "Starting Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        CurrencyExchRate2: array[2] of Record "AVU Add. VAT Exchange Rate";
        CurrencyCode2: array[2] of Code[10];
        Date2: array[2] of Date;

    procedure ExchangeAmtFCYToACY(Date: Date; CurrencyCode: Code[10]; Amount: Decimal): Decimal
    begin
        if CurrencyCode = '' then
            exit(Amount);

        FindCurrency(Date, CurrencyCode, 1);
        TestField("Exchange Rate Amount");
        TestField("Relational Exch. Rate Amount");
        Amount := (Amount / "Exchange Rate Amount") * "Relational Exch. Rate Amount";
        exit(Amount);
    end;

    procedure FindCurrency(Date: Date; CurrencyCode: Code[10]; CacheNo: Integer)
    begin
        if (CurrencyCode2[CacheNo] = CurrencyCode) and (Date2[CacheNo] = Date) then
            Rec := CurrencyExchRate2[CacheNo]
        else begin
            if Date = 0D then
                Date := WorkDate;
            CurrencyExchRate2[CacheNo].SetRange("Currency Code", CurrencyCode);
            CurrencyExchRate2[CacheNo].SetRange("Starting Date", 0D, Date);
            CurrencyExchRate2[CacheNo].FindLast;
            Rec := CurrencyExchRate2[CacheNo];
            CurrencyCode2[CacheNo] := CurrencyCode;
            Date2[CacheNo] := Date;
        end;
    end;

    procedure GetLastestExchangeRate(CurrencyCode: Code[10]; var Date: Date; var Amt: Decimal)
    begin
        Date := 0D;
        Amt := 0;
        SetRange("Currency Code", CurrencyCode);
        if FindLast then begin
            Date := "Starting Date";
            if "Exchange Rate Amount" <> 0 then
                Amt := "Relational Exch. Rate Amount" / "Exchange Rate Amount";
        end;
    end;
}

