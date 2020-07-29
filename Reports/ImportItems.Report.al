report 82005 "AVU Import Items"
{
    Caption = 'Import Items';
    UsageCategory = Administration;
    ApplicationArea = All;
    ProcessingOnly = true;

    //#region General
    requestpage
    {
        layout
        {
            area(Content)
            {
                group(GroupName)
                {
                    field(RowsToSkipField; RowsToSkip)
                    {
                        Caption = 'Rows to Skip';
                        ApplicationArea = All;
                    }
                    field(SheetNameField; SheetName)
                    {
                        Caption = 'Sheet Name';
                        ApplicationArea = All;
                    }
                }
            }
        }

        trigger OnOpenPage();
        begin
            RowsToSkip := 5;
            SheetName := 'Sheet0';
        end;
    }

    var
        InventorySetup: Record "Inventory Setup";
        RowsToSkip: Integer;
        SheetName: Text;
        ProcessingLbl: Label 'Processing Record #1####';
        FinishedLbl: Label 'Import finished successfully.';
        LengthErrorLbl: Label 'Field value ''%1'' is bigger than %2 chars in row %3';

    trigger OnPostReport()
    var
        ExcelBuffer: Record "Excel Buffer" temporary;
        FileName: Text;
        Ins: InStream;
    begin
        if not UploadIntoStream('Import', '', ' All Files (*.*)|*.*', FileName, Ins) THEN
            ERROR('Something wrong');

        ExcelBuffer.OpenBookStream(Ins, SheetName);
        ExcelBuffer.ReadSheet();

        CreateItems(ExcelBuffer);
        Message(FinishedLbl);
    end;
    //#endregion
    //#region CreateItems
    local procedure CreateItems(VAR ExcelBuffer: Record "Excel Buffer" temporary)
    var
        Window: Dialog;
    begin
        InventorySetup.Get();

        Window.Open(ProcessingLbl);
        ExcelBuffer.SetRange("Column No.", 1);
        ExcelBuffer.SetFilter("Row No.", '>%1', RowsToSkip);
        if ExcelBuffer.FindSet() then
            repeat
                Window.Update(1, ExcelBuffer."Cell Value as Text");
                CreateItem(ExcelBuffer);
            until ExcelBuffer.Next() = 0;
        Window.Close();
    end;
    //#endregion

    local procedure CreateItem(VAR SourceExcelBuffer: Record "Excel Buffer" temporary)
    var
        Item: Record Item;
        CountryRegion: Record "Country/Region";
        Region: Record "AVU Region";
        Vintage: Record "AVU Vintage";
        Volume: Record "AVU Volume";
        Alcohol: Record "AVU Alcohol Percent";
        Classification: Record "AVU Classification";
        ExcelBuffer: Record "Excel Buffer" temporary;
        Dec: Decimal;
        Int: Integer;
        RowNo: Integer;
    begin
        ExcelBuffer.Copy(SourceExcelBuffer, true);
        RowNo := SourceExcelBuffer."Row No.";
        Item.Init();
        Item."No." := TextToCode20(SourceExcelBuffer);
        Item."Costing Method" := InventorySetup."Default Costing Method";
        Item.Insert(true);

        Item.Validate("Base Unit of Measure", 'PZ');

        ExcelBuffer.Get(RowNo, 2); // vino
        if StrLen(ExcelBuffer."Cell Value as Text") > MaxStrLen(Item.Description) then begin
            Item.Validate(Description, 'LONG VALUE ' + Format(StrLen(ExcelBuffer."Cell Value as Text")));
            CreateItemText(Item."No.", ExcelBuffer."Cell Value as Text");
        end else
            Item.Validate(Description, CopyStr(ExcelBuffer."Cell Value as Text", 1, MaxStrLen(Item.Description)));
        if ExcelBuffer.Get(RowNo, 3) then // denominazione
            if StrLen(ExcelBuffer."Cell Value as Text") > MaxStrLen(Item."AVU Name") then
                Item."AVU Name" := 'LONG VALUE ' + Format(StrLen(ExcelBuffer."Cell Value as Text"))
            else
                Item."AVU Name" := CopyStr(ExcelBuffer."Cell Value as Text", 1, MaxStrLen(Item."AVU Name"));
        if ExcelBuffer.Get(RowNo, 4) then // idProduttore
            if ExcelBuffer."Cell Value as Text" <> '0' then
                Item."AVU Producer No." := TextToCode20(ExcelBuffer);
        if ExcelBuffer.Get(RowNo, 6) then begin // regione
            Region.SetRange(Description, ExcelBuffer."Cell Value as Text");
            Region.FindFirst();
            Item."AVU Region Code" := Region.Code;
        end;

        ExcelBuffer.Get(RowNo, 7); // nazione
        if ExcelBuffer."Cell Value as Text" = 'Accessories' then begin
            Item.Validate("Item Category Code", 'Accessories');
            Item.Validate("Gen. Prod. Posting Group", 'ACCESSORI');
            Item.Validate("VAT Prod. Posting Group", 'GOODS (STANDARD)');
            Item.Validate("Inventory Posting Group", 'ACCESSORI');
        end else begin
            Item.Validate("Item Category Code", 'VINI');
            CountryRegion.SetRange(Name, ExcelBuffer."Cell Value as Text");
            if not CountryRegion.FindFirst() then
                if ExcelBuffer."Cell Value as Text" = 'Olanda' then
                    CountryRegion.Get('NL');
            Item.Validate("AVU Country of Origin Code", CountryRegion.Code);
            Item.Validate("Gen. Prod. Posting Group", 'VINI');
            Item.Validate("VAT Prod. Posting Group", 'GOODS (STANDARD)');
            Item.Validate("Inventory Posting Group", 'VINI');
        end;

        ExcelBuffer.Get(RowNo, 8); // annata
        if Evaluate(Int, ExcelBuffer."Cell Value as Text") then begin
            Vintage.SetRange(Description, ExcelBuffer."Cell Value as Text");
            Vintage.FindFirst();
            Item."AVU Vintage Code" := Vintage.Code;
        end;

        ExcelBuffer.Get(RowNo, 9); // contenuto
        Volume.SetRange(Description, ExcelBuffer."Cell Value as Text");
        Volume.FindFirst();
        Item."AVU Volume Code" := Volume.Code;

        ExcelBuffer.Get(RowNo, 10); // colore
        Item."AVU Color Code" := ExcelBuffer."Cell Value as Text";
        /*Case ExcelBuffer."Cell Value as Text" of
            'Rosso':
                Item."AVU Color" := Item."AVU Color"::Red;
            'Bianco':
                Item."AVU Color" := Item."AVU Color"::White;
            'Dolce':
                Item."AVU Color" := Item."AVU Color"::Sweet;
            'Distillato':
                Item."AVU Color" := Item."AVU Color"::Distilled;
            'Frizzante':
                Item."AVU Color" := Item."AVU Color"::Sparkling;
            'Rosé':
                Item."AVU Color" := Item."AVU Color"::"Rosé";
            'Birra':
                Item."AVU Color" := Item."AVU Color"::Beer;
        end;*/

        ExcelBuffer.Get(RowNo, 11); // alcol
        if Evaluate(Dec, ExcelBuffer."Cell Value as Text") then begin
            Alcohol.Get(ExcelBuffer."Cell Value as Text");
            Item."AVU Alcohol Percent Code" := Alcohol.Code;
        end;

        if ExcelBuffer.Get(RowNo, 12) then begin // classificazione
            Classification.SetRange(Description, ExcelBuffer."Cell Value as Text");
            Classification.FindFirst();
            Item."AVU Classification Code" := Classification.Code;
        end;

        Item.Modify(true);
    end;


    local procedure CreateItemText(ItemNo: Code[20]; Text: Text)
    var
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        LineNo: Integer;
    begin
        ExtendedTextHeader.Init();
        ExtendedTextHeader."Table Name" := ExtendedTextHeader."Table Name"::Item;
        ExtendedTextHeader."No." := ItemNo;
        ExtendedTextHeader.Insert(true);

        repeat
            ExtendedTextLine.Init();
            ExtendedTextLine."Table Name" := ExtendedTextHeader."Table Name";
            ExtendedTextLine."No." := ExtendedTextHeader."No.";
            ExtendedTextLine."Text No." := ExtendedTextHeader."Text No.";
            ExtendedTextLine.Text := CopyStr(Text, 1, 50);
            LineNo += 10000;
            ExtendedTextLine."Line No." := LineNo;
            ExtendedTextLine.Insert(true);
            if StrLen(Text) > 50 then
                Text := CopyStr(Text, 51)
            else
                Text := '';
        until Text = '';
    end;

    local procedure TextToCode20(ExcelBuffer: Record "Excel Buffer"): Code[20]
    begin
        if StrLen(ExcelBuffer."Cell Value as Text") > 20 then
            Error(LengthErrorLbl, ExcelBuffer."Cell Value as Text", 20, ExcelBuffer."Row No.");
        Exit(CopyStr(ExcelBuffer."Cell Value as Text", 1, 20));
    end;

    local procedure TextToText100(ExcelBuffer: Record "Excel Buffer"): Text[100]
    begin
        if StrLen(ExcelBuffer."Cell Value as Text") > 100 then
            Error(LengthErrorLbl, ExcelBuffer."Cell Value as Text", 100, ExcelBuffer."Row No.");
        Exit(CopyStr(ExcelBuffer."Cell Value as Text", 1, 100));
    end;
}