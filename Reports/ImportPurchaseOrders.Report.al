report 82002 "AVU Import Purchase Orders"
{
    Caption = 'Import Purchase Orders';
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
            RowsToSkip := 1;
            SheetName := 'Sheet1';
        end;
    }

    var
        GLSetup: Record "General Ledger Setup";
        ContactMgmt: Codeunit "AVU Contact Management";
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

        CreateDocuments(ExcelBuffer);
        Message(FinishedLbl);
    end;
    //#endregion
    //#region CreateDocuments
    local procedure CreateDocuments(VAR ExcelBuffer: Record "Excel Buffer" temporary)
    var
        Window: Dialog;
    begin
        GLSetup.Get();
        GLSetup.TestField("LCY Code");

        Window.Open(ProcessingLbl);
        ExcelBuffer.SetRange("Column No.", 1);
        ExcelBuffer.SetFilter("Row No.", '>%1', RowsToSkip);
        if ExcelBuffer.FindSet() then
            repeat
                Window.Update(1, ExcelBuffer."Cell Value as Text");
                CreatePurchaseDocument(ExcelBuffer);
            until ExcelBuffer.Next() = 0;
        Window.Close();
    end;
    //#endregion

    local procedure InsertContact(VAR ExcelBuffer: Record "Excel Buffer" temporary; RowNo: Integer; LinkType: Option; LinkNo: Code[20])
    var
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
    begin
        ExcelBuffer.Get(RowNo, 1); // ID Contatto
        Contact.Get(ExcelBuffer."Cell Value as Text");

        if not ContBusRel.FindByContact(LinkType, Contact."No.") then
            ContBusRel.CreateRelation(Contact."No.", LinkNo, LinkType);
    end;

    local procedure InsertVendor(VAR ExcelBuffer: Record "Excel Buffer" temporary; RowNo: Integer; var Vendor: Record Vendor)
    var
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
    begin
        ExcelBuffer.Get(RowNo, 1); // ID Contatto
        Vendor."No." := TextToCode20(ExcelBuffer);
        InsertContact(ExcelBuffer, RowNo, ContBusRel."Link to Table"::Vendor, Vendor."No.");
        Contact.Get(Vendor."No.");
        ContactMgmt.CreateVendorFromContact(Contact);
        Vendor.Get(Vendor."No.");
    end;


    local procedure CreatePurchaseDocument(VAR SourceExcelBuffer: Record "Excel Buffer" temporary)
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        ExcelBuffer: Record "Excel Buffer" temporary;
        Factor: Decimal;
        Dec: Decimal;
        RowNo: Integer;
    begin
        ExcelBuffer.Copy(SourceExcelBuffer, true);
        RowNo := SourceExcelBuffer."Row No.";
        InsertVendor(ExcelBuffer, RowNo, Vendor);
        ExcelBuffer.Get(RowNo, 8); // vino (tutti articoli esclusi nazione accessori)
        Evaluate(Dec, ExcelBuffer."Cell Value as Text");

        PurchaseHeader.Init();
        if Dec > 0 then
            PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::"Credit Memo"
        else
            PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        ExcelBuffer.Get(RowNo, 2); // date / time
        PurchaseHeader."Posting Date" := GetDate(ExcelBuffer."Cell Value as Text");
        PurchaseHeader.InitRecord();
        PurchaseHeader.Insert(true);

        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        ExcelBuffer.Get(RowNo, 2); // date / time
        PurchaseHeader.Validate("Posting Date", GetDate(ExcelBuffer."Cell Value as Text"));
        ExcelBuffer.Get(RowNo, 3); // currency
        if not (ExcelBuffer."Cell Value as Text" in [GLSetup."LCY Code", 'NULL']) then
            PurchaseHeader.Validate("Currency Code", ExcelBuffer."Cell Value as Text");
        ExcelBuffer.Get(RowNo, 4); // exchange rate
        Evaluate(Factor, ExcelBuffer."Cell Value as Text");
        PurchaseHeader.Validate("Currency Factor", Factor);
        ExcelBuffer.Get(RowNo, 6); // external no.
        if Dec > 0 then
            PurchaseHeader."Vendor Cr. Memo No." := CopyStr(ExcelBuffer."Cell Value as Text", 1, 35)
        else
            PurchaseHeader."Vendor Invoice No." := CopyStr(ExcelBuffer."Cell Value as Text", 1, 35);
        if PurchaseHeader."Currency Code" = '' then
            PurchaseHeader.Validate("Vendor Posting Group", GLSetup."LCY Code")
        else
            PurchaseHeader.Validate("Vendor Posting Group", PurchaseHeader."Currency Code");

        ExcelBuffer.Get(RowNo, 7); // Bus. Posting Group
        PurchaseHeader.Validate("Gen. Bus. Posting Group", TextToCode20(ExcelBuffer));

        /*        Case PurchaseHeader."Buy-from Country/Region Code" OF
                    'CH':
                        PurchaseHeader.Validate("Gen. Bus. Posting Group", 'NAZIONALE');
                    'GB':
                        PurchaseHeader.Validate("Gen. Bus. Posting Group", 'UK');
                    else
                        PurchaseHeader.Validate("Gen. Bus. Posting Group", 'ESTERO');
                end;*/
        PurchaseHeader.Validate("VAT Bus. Posting Group", 'NO IVA');
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Modify(true);

        CreatePurchaseLine(PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseHeader."Gen. Bus. Posting Group", Abs(Dec), 0, 'VINI');
        Commit();

        PurchaseHeader.Invoice := true;
        PurchaseHeader.Receive := true;
        Codeunit.Run(Codeunit::"Purch.-Post", PurchaseHeader);
        Commit();
    end;

    local procedure CreatePurchaseLine(DocumentType: Option; DocumentNo: code[20]; BusGroup: code[20]; Amount: Decimal; Discount: Decimal; ProdGroup: code[20])
    var
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        LineNo: Integer;
    begin
        if Amount = 0 then
            exit;

        GeneralPostingSetup.Get(BusGroup, ProdGroup);
        GeneralPostingSetup.TestField("Purch. Account");
        PurchaseLine.SETRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        if PurchaseLine.FindLast() then
            LineNo := PurchaseLine."Line No.";

        PurchaseLine.Init();
        PurchaseLine."Document Type" := DocumentType;
        PurchaseLine."Document No." := DocumentNo;
        PurchaseLine."Line No." := LineNo + 10000;
        PurchaseLine.Validate(Type, PurchaseLine.Type::"G/L Account");
        PurchaseLine.Validate("No.", GeneralPostingSetup."Purch. Account");
        PurchaseLine.Validate(Quantity, 1);

        PurchaseLine.Validate("Direct Unit Cost", Amount);
        PurchaseLine.Validate("Gen. Prod. Posting Group", ProdGroup);
        PurchaseLine.Validate("VAT Prod. Posting Group", 'NORMALE');
        if Discount > 0 then
            PurchaseLine.Validate("Line Discount Amount", Discount);
        PurchaseLine.Insert(True);
    end;

    local procedure GetDate(Text: Text): Date
    var
        Day: Integer;
        Month: Integer;
        Year: Integer;
    begin
        Text := DelChr(Text, '=', '.');
        Evaluate(Day, CopyStr(Text, 1, 2));
        Evaluate(Month, CopyStr(Text, 3, 2));
        Evaluate(Year, CopyStr(Text, 5, 4));
        exit(DMY2Date(Day, Month, Year));
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