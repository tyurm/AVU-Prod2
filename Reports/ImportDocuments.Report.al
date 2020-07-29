report 82000 "AVU Import Documents"
{
    Caption = 'Import Documents';
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
        CreatedDocuments: Integer;

    trigger OnPostReport()
    var
        ExcelBuffer: Record "Excel Buffer" temporary;
        //UpdateDiscountAndVATDiff: Codeunit "Update Discount and VAT Diff";
        FileName: Text;
        Ins: InStream;
    begin
        if not UploadIntoStream('Import', '', ' All Files (*.*)|*.*', FileName, Ins) THEN
            ERROR('Something wrong');

        ExcelBuffer.OpenBookStream(Ins, SheetName);
        ExcelBuffer.ReadSheet();

        CreateDocuments(ExcelBuffer);
        //commit;
        //UpdateDiscountAndVATDiff.run;
        Message(FinishedLbl);
    end;
    //#endregion
    //#region CreateDocuments
    local procedure CreateDocuments(VAR ExcelBuffer: Record "Excel Buffer" temporary)
    var
        ExcelBuffer2: Record "Excel Buffer" temporary;
        CurrentDocNo: Text;
        Window: Dialog;
    begin
        GLSetup.Get();
        GLSetup.TestField("LCY Code");
        ExcelBuffer2.Copy(ExcelBuffer, true);

        Window.Open(ProcessingLbl);
        ExcelBuffer.SetRange("Column No.", 1);
        ExcelBuffer.SetFilter("Row No.", '>%1', RowsToSkip);
        if ExcelBuffer.FindSet() then
            repeat
                if ExcelBuffer2.Get(ExcelBuffer."Row No.", 8) then // PO/SO number
                    if CurrentDocNo <> ExcelBuffer2."Cell Value as Text" then begin
                        CurrentDocNo := ExcelBuffer2."Cell Value as Text";
                        Window.Update(1, ExcelBuffer2."Cell Value as Text");
                        case UpperCase(CopyStr(ExcelBuffer2."Cell Value as Text", 1, 2)) of
                            'PO':
                                HandlePurchaseOrder(ExcelBuffer2, ExcelBuffer."Row No.", ExcelBuffer2."Cell Value as Text");
                            'SC':
                                HandlePurchaseCrMemo(ExcelBuffer2, ExcelBuffer."Row No.", ExcelBuffer2."Cell Value as Text");
                            'SO', 'PF':
                                HandleSalesOrder(ExcelBuffer2, ExcelBuffer."Row No.", ExcelBuffer2."Cell Value as Text");
                            'CN':
                                HandleSalesCrMemo(ExcelBuffer2, ExcelBuffer."Row No.", ExcelBuffer2."Cell Value as Text");
                        end;
                    end;
            until ExcelBuffer.Next() = 0;
        Window.Close();
    end;
    //#endregion
    //#region FindDocument
    local procedure HandleSalesOrder(var ExcelBuffer: Record "Excel Buffer" temporary; RowNo: Integer; DocumentNo: Text)
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("No.", DocumentNo);
        if not SalesHeader.IsEmpty() then
            exit;

        SalesInvoiceHeader.SetRange("No.", DocumentNo);
        if not SalesInvoiceHeader.IsEmpty() then
            exit;

        CreateSalesOrder(ExcelBuffer, RowNo);
    end;

    local procedure HandleSalesCrMemo(var ExcelBuffer: Record "Excel Buffer" temporary; RowNo: Integer; DocumentNo: Text)
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.SetRange("No.", DocumentNo);
        if not SalesHeader.IsEmpty() then
            exit;

        SalesCrMemoHeader.SetRange("No.", DocumentNo);
        if not SalesCrMemoHeader.IsEmpty() then
            exit;

        CreateSalesCreditMemo(ExcelBuffer, RowNo);
    end;

    local procedure HandlePurchaseOrder(var ExcelBuffer: Record "Excel Buffer" temporary; RowNo: Integer; DocumentNo: Text)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("No.", DocumentNo);
        if not PurchaseHeader.IsEmpty() then
            exit;

        PurchInvHeader.SetRange("No.", DocumentNo);
        if not PurchInvHeader.IsEmpty() then
            exit;

        CreatePurchaseOrder(ExcelBuffer, RowNo);
    end;

    local procedure HandlePurchaseCrMemo(var ExcelBuffer: Record "Excel Buffer" temporary; RowNo: Integer; DocumentNo: Text)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseHeader.SetRange("No.", DocumentNo);
        if not PurchaseHeader.IsEmpty() then
            exit;

        PurchCrMemoHdr.SetRange("No.", DocumentNo);
        if not PurchCrMemoHdr.IsEmpty() then
            exit;

        CreatePurchaseCreditMemo(ExcelBuffer, RowNo);
    end;
    //#endregion
    //#region Create Contact/Vendor/Customer
    local procedure InsertContact(VAR ExcelBuffer: Record "Excel Buffer" temporary; RowNo: Integer; LinkType: Option; LinkNo: Code[20])
    var
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
    begin
        ExcelBuffer.Get(RowNo, 1); // ID Contatto
        if not Contact.Get(ExcelBuffer."Cell Value as Text") then begin
            Contact.SetSkipDefault();
            Contact.Init();
            Contact."No." := TextToCode20(ExcelBuffer);
            if ExcelBuffer.Get(RowNo, 2) then // Azienda, cognome, nome
                Contact.Name := TextToText100(ExcelBuffer);
            Contact.Insert(True);
        end;

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
        if Vendor.get(Vendor."No.") then
            exit;
        InsertContact(ExcelBuffer, RowNo, ContBusRel."Link to Table"::Vendor, Vendor."No.");
        Contact.Get(Vendor."No.");
        ContactMgmt.CreateVendorFromContact(Contact);
        Vendor.Get(Vendor."No.");
        ExcelBuffer.Get(RowNo, 7); // country
        if ExcelBuffer."Cell Value as Text" = 'Svizzera' then
            Vendor.Validate("Gen. Bus. Posting Group", 'NAZIONALE')
        else
            Vendor.Validate("Gen. Bus. Posting Group", 'ESTERO');
        Vendor.Validate("Vendor Posting Group", Vendor."Gen. Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", Vendor."Gen. Bus. Posting Group");
        Vendor.Modify(True);
    end;

    local procedure InsertCustomer(VAR ExcelBuffer: Record "Excel Buffer" temporary; RowNo: Integer; var Customer: Record Customer)
    var
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
    begin
        ExcelBuffer.Get(RowNo, 1); // ID Contatto
        Customer."No." := TextToCode20(ExcelBuffer);
        if Customer.get(Customer."No.") then
            exit;
        InsertContact(ExcelBuffer, RowNo, ContBusRel."Link to Table"::Customer, Customer."No.");
        Contact.Get(Customer."No.");
        ContactMgmt.CreateCustomerFromContact(Contact);
        Customer.Get(Customer."No.");
        ExcelBuffer.Get(RowNo, 7); // country
        if ExcelBuffer."Cell Value as Text" = 'Svizzera' then begin
            Customer.Validate("Customer Posting Group", 'NAZIONALE');
            Customer.Validate("Gen. Bus. Posting Group", 'NAZIONALE');
        end else begin
            Customer.Validate("Customer Posting Group", 'ESTERO');
            Customer.Validate("Gen. Bus. Posting Group", 'ESTERO');
        end;
        Customer.Validate("VAT Bus. Posting Group", Customer."Gen. Bus. Posting Group");
        Customer.Modify(True);
    end;
    //#endregion
    //#region CreateSalesOrder
    local procedure CreateSalesOrder(VAR ExcelBuffer: Record "Excel Buffer" temporary; RowNo: Integer)
    var
        SalesHeader: Record "Sales Header";
        Customer: record Customer;
        SalesPerson: Record "Salesperson/Purchaser";
        CountryRegion: Record "Country/Region";
        Contact: Record Contact;
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        ReleaseSalesDoc: Codeunit "Release Sales Document";
        //SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        DocumentType: Text;
        ProductGroup: Code[20];
        Dec: Decimal;
        Discount: Decimal;
        VAT: Decimal;
        DocumentTotal: Decimal;
        TotalAmount: Decimal;
        TotalVAT: Decimal;
        TotalAmtInclVat: decimal;
    begin
        InsertCustomer(ExcelBuffer, RowNo, Customer);
        SalesHeader.Init();
        SalesHeader.SetHideValidationDialog(true);
        ExcelBuffer.Get(RowNo, 8); // PO/SO number
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := TextToCode20(ExcelBuffer);
        SalesHeader."Posting No." := SalesHeader."No.";
        SalesHeader."Shipping No." := SalesHeader."No.";
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        if not SalesHeader.Insert(true) then
            exit;
        CreatedDocuments += 1;
        if ExcelBuffer.Get(RowNo, 2) then // Azienda, cognome, nome
            SalesHeader."Sell-to Customer Name" := TextToText100(ExcelBuffer);
        if ExcelBuffer.Get(RowNo, 3) then // via 1
            SalesHeader.Validate("Sell-to Address", ExcelBuffer."Cell Value as Text");
        if ExcelBuffer.Get(RowNo, 4) then // via 2
            SalesHeader.Validate("Sell-to Address 2", ExcelBuffer."Cell Value as Text");
        ExcelBuffer.Get(RowNo, 5); // city
        SalesHeader.Validate("Sell-to City", ExcelBuffer."Cell Value as Text");
        if ExcelBuffer.Get(RowNo, 6) then // zip
            SalesHeader.Validate("Sell-to Post Code", ExcelBuffer."Cell Value as Text");
        ExcelBuffer.Get(RowNo, 7); // country
        CountryRegion.SetRange(Name, ExcelBuffer."Cell Value as Text");
        if not CountryRegion.FindFirst() then
            if ExcelBuffer."Cell Value as Text" = 'Olanda' then
                CountryRegion.Get('NL');

        SalesHeader.Validate("Sell-to Country/Region Code", CountryRegion.Code);
        ExcelBuffer.Get(RowNo, 11); // date / time
        SalesHeader.Validate("Posting Date", GetDate(ExcelBuffer."Cell Value as Text"));
        if ExcelBuffer.Get(RowNo, 42) then // SHIPPED DATE
            SalesHeader.Validate("Shipment Date", GetDate(ExcelBuffer."Cell Value as Text"));
        SalesHeader.Validate("Order Date", SalesHeader."Posting Date");

        if ExcelBuffer.Get(RowNo, 12) then begin // contatto avu attuale
            if not SalesPerson.Get(ExcelBuffer."Cell Value as Text") then begin
                SalesPerson.Init();
                SalesPerson.Code := TextToCode20(ExcelBuffer);
                SalesPerson.Insert(true);
            end;
            SalesHeader.Validate("Salesperson Code", ExcelBuffer."Cell Value as Text");
        end;
        if ExcelBuffer.Get(RowNo, 13) then begin // assegnatario
            if not SalesPerson.Get(ExcelBuffer."Cell Value as Text") then begin
                SalesPerson.Init();
                SalesPerson.Code := TextToCode20(ExcelBuffer);
                SalesPerson.Insert(true);
            end;
            SalesHeader.Validate("AVU Assignee Code", ExcelBuffer."Cell Value as Text");
        end;
        ExcelBuffer.Get(RowNo, 15); // currency
        if not (ExcelBuffer."Cell Value as Text" in [GLSetup."LCY Code", 'NULL']) then
            SalesHeader.Validate("Currency Code", ExcelBuffer."Cell Value as Text")
        else
            if SalesHeader."Currency Code" <> '' then //fix issue when foreign currency was taken from Customer
                SalesHeader.Validate("Currency Code", '');
        ExcelBuffer.Get(RowNo, 16); // exchange rate
        Evaluate(Dec, ExcelBuffer."Cell Value as Text");
        // if Dec = -1 then
        //     SalesHeader.Validate("Currency Factor", 1.126899982)
        // else
        //     SalesHeader.Validate("Currency Factor", 1 / Dec);
        if not ExcelBuffer.Get(RowNo, 40) then // payment terms
            ExcelBuffer."Cell Value as Text" := 'On receipt of Invoice and prior to Collection';
        SalesHeader.Validate("Payment Terms Code", GetPaymentTermsCode(ExcelBuffer."Cell Value as Text"));

        //ExcelBuffer.Get(RowNo, 7); // country
        //if ExcelBuffer."Cell Value as Text" = 'Svizzera' then
        //    SalesHeader.Validate("Customer Posting Group", 'NAZIONALE')
        //else
        //    SalesHeader.Validate("Customer Posting Group", 'ESTERO');
        if ExcelBuffer.Get(RowNo, 9) then // Supplier/Client Reference
            SalesHeader."Your Reference" := ExcelBuffer."Cell Value as Text";
        ExcelBuffer.Get(RowNo, 10); // tipo (Fattura/Acquisto/ NDC)
        DocumentType := ExcelBuffer."Cell Value as Text";
        ExcelBuffer.Get(RowNo, 7); // country
        //if ExcelBuffer."Cell Value as Text" = 'Svizzera' then
        //    SalesHeader.Validate("Customer Posting Group", 'NAZIONALE')
        //else
        //    SalesHeader.Validate("Customer Posting Group", 'ESTERO');
        //if ExcelBuffer."Cell Value as Text" = 'Svizzera' then
        //    SalesHeader.Validate("Gen. Bus. Posting Group", 'NAZIONALE')
        //else
        //    SalesHeader.Validate("Gen. Bus. Posting Group", 'ESTERO');
        ExcelBuffer.Get(RowNo, 26); // iva
        Evaluate(VAT, ExcelBuffer."Cell Value as Text");
        if Contact.Get(SalesHeader."Sell-to Customer No." + '_') then
            SalesHeader.Validate("Sell-to Contact No.", SalesHeader."Sell-to Customer No." + '_');
        SalesHeader.Validate("Location Code", 'CH');
        SalesHeader.Modify(true);

        ExcelBuffer.Get(RowNo, 18); // vino (tutti articoli esclusi nazione accessori)
        Evaluate(Dec, ExcelBuffer."Cell Value as Text");
        if Dec > 0 then
            ProductGroup := 'VINI';
        ExcelBuffer.Get(RowNo, 21); // sconto
        Evaluate(Discount, ExcelBuffer."Cell Value as Text");

        if (DocumentType = 'FatturaSemplice') or (DocumentType = 'FatturaFinanziaria') then begin
            if ExcelBuffer.Get(RowNo, 20) then // finanziarie descrizione
                CreateSalesLine(SalesHeader, SalesHeader."Gen. Bus. Posting Group", ABS(Dec), 0, GetProductGroup(ExcelBuffer."Cell Value as Text"), VAT);
        end else
            CreateSalesItemLines(SalesHeader, ExcelBuffer, RowNo, VAT);

        ExcelBuffer.Get(RowNo, 22); // spese spedizioni
        Evaluate(Dec, ExcelBuffer."Cell Value as Text");
        CreateSalesLine(SalesHeader, SalesHeader."Gen. Bus. Posting Group", ABS(Dec), 0, 'SPESE SPEDIZIONI', VAT);

        ExcelBuffer.Get(RowNo, 23); // imballaggio
        Evaluate(Dec, ExcelBuffer."Cell Value as Text");
        CreateSalesLine(SalesHeader, SalesHeader."Gen. Bus. Posting Group", ABS(Dec), 0, 'IMBALLAGGI', VAT);

        ExcelBuffer.Get(RowNo, 24); // assicurazione
        Evaluate(Dec, ExcelBuffer."Cell Value as Text");
        CreateSalesLine(SalesHeader, SalesHeader."Gen. Bus. Posting Group", ABS(Dec), 0, 'ASSICURAZIONE', VAT);

        ExcelBuffer.Get(RowNo, 28); // inventory impact EUR
        Evaluate(Dec, ExcelBuffer."Cell Value as Text");
        /*if StrPos(DocumentType, 'Proforma') = 1 then begin
            SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
            SalesHeader.Validate("Prepayment %", 100);
            SalesHeader."Prepayment No." := SalesHeader."No." + '_';
            SalesHeader.Modify(true);
        end;*/
        //Commit();
        AllowInvDiscOnGLLines(SalesHeader);
        ExcelBuffer.Get(RowNo, 21); // sconto
        Evaluate(Discount, ExcelBuffer."Cell Value as Text");
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(Discount, SalesHeader);

        //try rounding fix
        ExcelBuffer.Get(RowNo, 14);
        Evaluate(Dec, ExcelBuffer."Cell Value as Text");
        TotalAmtInclVat := round(dec, 0.01);

        ExcelBuffer.Get(RowNo, 26);
        Evaluate(Dec, ExcelBuffer."Cell Value as Text");
        TotalVAT := round(dec, 0.01);

        TotalAmount := TotalAmtInclVat - TotalVAT;

        SalesHeader.get(SalesHeader."Document Type", SalesHeader."No.");
        SalesHeader.calcfields("Amount Including VAT", Amount);

        if (SalesHeader.Amount <> TotalAmount) and ((SalesHeader."Amount Including VAT" - SalesHeader.Amount) <> round(TotalVAT, 0.01)) then begin
            Discount += SalesHeader.Amount - TotalAmount;
            SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(Discount, SalesHeader);
            UpdateSalesLineVAT(SalesHeader, ABS(TotalVAT));
        end;
        if (SalesHeader.Amount = TotalAmount) and ((SalesHeader."Amount Including VAT" - SalesHeader.Amount) <> round(TotalVAT, 0.01)) then begin
            //Discount += SalesHeader.Amount - TotalAmount;
            //SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(Discount, SalesHeader);
            UpdateSalesLineVAT(SalesHeader, ABS(TotalVAT));
        end;
        if (SalesHeader.Amount <> TotalAmount) and ((SalesHeader."Amount Including VAT" - SalesHeader.Amount) = round(TotalVAT, 0.01)) then begin
            Discount += SalesHeader.Amount - TotalAmount;
            SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(Discount, SalesHeader);
            UpdateSalesLineVAT(SalesHeader, ABS(TotalVAT));
        end;

        ReleaseSalesDoc.PerformManualRelease(SalesHeader);
        //fix end
        Commit();

    end;

    procedure AllowInvDiscOnGLLines(SalesHeader: record "Sales Header")
    var
        SalesLine: record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.setrange(type, SalesLine.type::Item);
        if NOT SalesLine.IsEmpty then
            exit;
        SalesLine.setrange(type, SalesLine.type::"G/L Account");
        if SalesLine.FindSet(true, false) then
            repeat
                SalesLine.Validate("Allow Invoice Disc.", true);
                SalesLine.modify(true);
            until SalesLine.next = 0;
    end;

    local procedure CreateSalesItemLines(SalesHeader: Record "Sales Header"; var ExcelBuffer: Record "Excel Buffer" temporary; RowNo: Integer; VAT: Decimal)
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Dec: Decimal;
        Finish: Boolean;
        LineNo: Integer;
        Int: Integer;
    begin
        repeat
            if not ExcelBuffer.Get(RowNo, 8) then // PO/SO number
                Finish := true;
            if not Finish and (UPPERCASE(ExcelBuffer."Cell Value as Text") = SalesHeader."No.") then begin
                ExcelBuffer.Get(RowNo, 29); // ID vino completo
                if Item.Get(ExcelBuffer."Cell Value as Text") then begin
                    // if Item."VAT Prod. Posting Group" <> 'GOODS (STANDARD)' then begin
                    //     Item.Validate("VAT Prod. Posting Group", 'GOODS (STANDARD)');
                    //     Item.Modify(true);
                    // end;

                    SalesLine.Init();
                    SalesLine."Document Type" := SalesHeader."Document Type";
                    SalesLine."Document No." := SalesHeader."No.";
                    LineNo += 10000;
                    SalesLine."Line No." := LineNo;
                    SalesLine.Validate(Type, SalesLine.Type::Item);
                    SalesLine.Validate("No.", Item."No.");
                    SalesLine.Validate("Location Code", 'CH');
                    ExcelBuffer.Get(RowNo, 30); // Qty Vino
                    Evaluate(Int, ExcelBuffer."Cell Value as Text");
                    SalesLine.Validate(Quantity, ABS(Int));
                    ExcelBuffer.Get(RowNo, 33); // PV vino
                    Evaluate(Dec, ExcelBuffer."Cell Value as Text");
                    SalesLine.Validate("Unit Price", ABS(Dec));
                    if VAT = 0 then
                        SalesLine.Validate("VAT Prod. Posting Group", 'NO VAT')
                    else
                        if SalesLine."VAT BUS. Posting Group" = 'ESTERO' then
                            SalesLine.Validate("VAT Prod. Posting Group", 'GOODS (VAT)');
                    SalesLine.Insert(True);
                end;
            end else
                Finish := true;
            RowNo += 1;
        until Finish;
    end;

    local procedure CreateSalesLine(SalesHeader: Record "Sales Header"; BusGroup: code[20]; Amount: Decimal; Discount: Decimal; ProdGroup: code[20]; VAT: Decimal)
    var
        SalesLine: Record "Sales Line";
        Account: Code[20];
        LineNo: Integer;
    begin
        if Amount = 0 then
            exit;

        case ProdGroup of
            /*'ACCESSORI':
                Account := '3301';*/
            'SPESE SPEDIZIONI':
                Account := '3500';
            'IMBALLAGGI':
                Account := '3610';
            'ASSICURAZIONE':
                Account := '3510';
            'GARANZIA BANCARIA':
                Account := '3660';
            'CERTIFICATO':
                Account := '3620';
            'INTERESSI DI MORA':
                Account := '3670';
            'ROUNDING':
                Account := '3820';
            else
                Error('Sales %1', ProdGroup);
        end;
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindLast() then
            LineNo := SalesLine."Line No.";

        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LineNo + 10000;
        SalesLine.Validate(Type, SalesLine.Type::"G/L Account");
        SalesLine.Validate("No.", Account);
        SalesLine.Validate(Quantity, 1);
        SalesLine.Validate("Unit Price", Amount);
        if VAT = 0 then
            SalesLine.Validate("VAT Prod. Posting Group", 'NO VAT');
        IF ProdGroup <> 'ROUNDING' THEN
            SalesLine.Description := ProdGroup;
        SalesLine.Insert(True);
    end;

    local procedure CreateSalesLineCost(DocumentType: Option; DocumentNo: Code[20]; Amount: Decimal; ProductGroup: Code[20])
    var
        SalesLine: Record "Sales Line";
        LineNo: Integer;
    begin
        if Amount = 0 then
            exit;

        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        if SalesLine.FindLast() then
            LineNo := SalesLine."Line No.";

        SalesLine.Init();
        SalesLine."Document Type" := DocumentType;
        SalesLine."Document No." := DocumentNo;
        SalesLine."Line No." := LineNo + 10000;
        SalesLine.Validate(Type, SalesLine.Type::" ");
        SalesLine.Validate("No.", 'COST');
        SalesLine.Validate(Description, Format(Amount));
        SalesLine."Posting Group" := ProductGroup;
        SalesLine.Insert(True);
    end;

    local procedure UpdateSalesLineVAT(var SalesHeader: Record "Sales Header"; VAT: Decimal)
    var
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        VATAmountLine: Record "VAT Amount Line" temporary;
        SalesPost: Codeunit "Sales-Post";
        ReleaseSalesDoc: Codeunit "Release Sales Document";
        VATAmount: Decimal;
    begin

        SalesPost.GetSalesLines(SalesHeader, TempSalesLine, 1);
        TempSalesLine.CalcVATAmountLines(0, SalesHeader, TempSalesLine, VATAmountLine);
        TempSalesLine.UpdateVATOnLines(0, SalesHeader, TempSalesLine, VATAmountLine);
        VATAmount := VATAmountLine.GetTotalVATAmount();
        if Round(VATAmount, 0.01) = Round(VAT, 0.01) then
            exit;

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("VAT Identifier", '7.7%');
        SalesLine.FindFirst();
        SalesLine."VAT Difference" := Round(VAT, 0.01) - Round(VATAmount, 0.01);
        SalesLine.Modify();
        ReleaseSalesDoc.CalcAndUpdateVATOnLines(SalesHeader, SalesLine);
    end;

    local procedure PostPayment(SalesHeader: Record "Sales Header"; Amount: Decimal)
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        LineNo: Integer;
    begin
        GenJnlTemplate.Get('PAGAM');
        GenJnlBatch.Get(GenJnlTemplate.Name, 'GENERALE');
        GenJournalLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        //GenJournalLine.DeleteAll(true);
        if GenJournalLine.FindLast() then
            LineNo := GenJournalLine."Line No." + 10000
        else
            LineNo := 10000;

        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := GenJnlBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJnlBatch.Name;
        GenJournalLine."Line No." := LineNo;
        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then
            GenJournalLine."Document Type" := GenJournalLine."Document Type"::Refund
        else
            GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment;
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
        GenJournalLine."Source Code" := GenJnlTemplate."Source Code";
        GenJournalLine."Reason Code" := GenJnlBatch."Reason Code";
        GenJournalLine."Journal Batch Id" := GenJnlBatch.Id;
        GenJournalLine.Insert(true);

        GenJournalLine.Validate("Posting Date", DMY2Date(31, 12, 2018));
        GenJournalLine.Validate("Document No.", SalesHeader."No.");
        GenJournalLine.Validate("External Document No.", SalesHeader."No.");
        GenJournalLine.Validate("Account No.", SalesHeader."Sell-to Customer No.");
        GenJournalLine.Validate("Currency Code", SalesHeader."Currency Code");
        GenJournalLine."Currency Factor" := SalesHeader."Currency Factor";
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        if SalesHeader."Currency Code" = '' then
            GenJournalLine.Validate("Bal. Account No.", 'UBS EUR')
        else
            GenJournalLine.Validate("Bal. Account No.", 'UBS ' + SalesHeader."Currency Code");
        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then
            GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::"Credit Memo")
        else
            GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", SalesHeader."No.");
        if Amount = 0 then begin
            CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive, "Due Date");
            CustLedgEntry.SetRange("Customer No.", GenJournalLine."Account No.");
            CustLedgEntry.SetRange(Open, true);
            CustLedgEntry.SetRange("Document Type", GenJournalLine."Applies-to Doc. Type");
            CustLedgEntry.SetRange("Document No.", GenJournalLine."Applies-to Doc. No.");
            CustLedgEntry.FindFirst();
            CustLedgEntry.CalcFields("Remaining Amount");
            Amount := CustLedgEntry."Remaining Amount";
        end;
        GenJournalLine.Validate(Amount, -Amount);
        GenJournalLine.Modify(true);
        Commit();
        //Codeunit.Run(Codeunit::"Gen. Jnl.-Post", GenJournalLine);
        //Commit();
    end;
    //#endregion
    //#region CreateSalesCreditMemo
    local procedure CreateSalesCreditMemo(VAR ExcelBuffer: Record "Excel Buffer" temporary; RowNo: Integer)
    var
        SalesHeader: Record "Sales Header";
        Customer: record Customer;
        SalesPerson: Record "Salesperson/Purchaser";
        CountryRegion: Record "Country/Region";
        Contact: Record Contact;
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        ReleaseSalesDoc: Codeunit "Release Sales Document";
        Dec: Decimal;
        Discount: Decimal;
        VAT: Decimal;
        DocumentTotal: Decimal;
        TotalAmount: Decimal;
        TotalVAT: Decimal;
        TotalAmtInclVat: decimal;
    begin
        InsertCustomer(ExcelBuffer, RowNo, Customer);
        SalesHeader.Init();
        SalesHeader.SetHideValidationDialog(true);
        ExcelBuffer.Get(RowNo, 8); // PO/SO number
        SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
        SalesHeader."No." := TextToCode20(ExcelBuffer);
        SalesHeader."Posting No." := SalesHeader."No.";
        SalesHeader."Return Receipt No." := SalesHeader."No.";
        SalesHeader.validate("Sell-to Customer No.", Customer."No.");
        if not SalesHeader.Insert(true) then
            exit;
        CreatedDocuments += 1;
        ExcelBuffer.Get(RowNo, 2); // Azienda, cognome, nome
        SalesHeader."Sell-to Customer Name" := TextToText100(ExcelBuffer);
        if ExcelBuffer.Get(RowNo, 3) then // via 1
            SalesHeader.Validate("Sell-to Address", ExcelBuffer."Cell Value as Text");
        if ExcelBuffer.Get(RowNo, 4) then // via 2
            SalesHeader.Validate("Sell-to Address 2", ExcelBuffer."Cell Value as Text");
        ExcelBuffer.Get(RowNo, 5); // city
        SalesHeader.Validate("Sell-to City", ExcelBuffer."Cell Value as Text");
        if ExcelBuffer.Get(RowNo, 6) then // zip
            SalesHeader.Validate("Sell-to Post Code", ExcelBuffer."Cell Value as Text");
        ExcelBuffer.Get(RowNo, 7); // country
        CountryRegion.SetRange(Name, ExcelBuffer."Cell Value as Text");
        CountryRegion.FindFirst();
        SalesHeader.Validate("Sell-to Country/Region Code", CountryRegion.Code);
        if ExcelBuffer.Get(RowNo, 9) then // Supplier/Client Reference
            SalesHeader."Your Reference" := ExcelBuffer."Cell Value as Text";
        ExcelBuffer.Get(RowNo, 11); // date / time
        SalesHeader.Validate("Posting Date", GetDate(ExcelBuffer."Cell Value as Text"));
        SalesHeader.Validate("Order Date", SalesHeader."Posting Date");
        if ExcelBuffer.Get(RowNo, 12) then begin // contatto avu
            if not SalesPerson.Get(ExcelBuffer."Cell Value as Text") then begin
                SalesPerson.Init();
                SalesPerson.Code := TextToCode20(ExcelBuffer);
                SalesPerson.Insert(true);
            end;
            SalesHeader.Validate("Salesperson Code", ExcelBuffer."Cell Value as Text");
        end;
        if ExcelBuffer.Get(RowNo, 13) then begin // assegnatario
            if not SalesPerson.Get(ExcelBuffer."Cell Value as Text") then begin
                SalesPerson.Init();
                SalesPerson.Code := TextToCode20(ExcelBuffer);
                SalesPerson.Insert(true);
            end;
            SalesHeader.Validate("AVU Assignee Code", ExcelBuffer."Cell Value as Text");
        end;
        if ExcelBuffer.Get(RowNo, 15) then // currency
            if not (ExcelBuffer."Cell Value as Text" in [GLSetup."LCY Code", 'NULL']) then
                SalesHeader.Validate("Currency Code", ExcelBuffer."Cell Value as Text")
            else
                if SalesHeader."Currency Code" <> '' then //fix issue when foreign currency was taken from Customer
                    SalesHeader.Validate("Currency Code", '');
        ExcelBuffer.Get(RowNo, 16); // exchange rate
        Evaluate(Dec, ExcelBuffer."Cell Value as Text");
        //SalesHeader.Validate("Currency Factor", 1 / Dec);
        if not ExcelBuffer.Get(RowNo, 40) then // payment terms
            ExcelBuffer."Cell Value as Text" := 'On receipt of Invoice and prior to Collection';
        SalesHeader.Validate("Payment Terms Code", GetPaymentTermsCode(ExcelBuffer."Cell Value as Text"));
        //f SalesHeader."Sell-to Country/Region Code" = 'CH' then
        //    SalesHeader.Validate("Customer Posting Group", 'NAZIONALE')
        //else
        //    SalesHeader.Validate("Customer Posting Group", 'ESTERO');
        SalesHeader.Validate("Gen. Bus. Posting Group", SalesHeader."Customer Posting Group");

        ExcelBuffer.Get(RowNo, 26); // iva
        Evaluate(VAT, ExcelBuffer."Cell Value as Text");
        if Contact.Get(SalesHeader."Sell-to Customer No." + '_') then
            SalesHeader.Validate("Sell-to Contact No.", SalesHeader."Sell-to Customer No." + '_');
        SalesHeader.Validate("Location Code", 'CH');
        SalesHeader.Modify(true);

        ExcelBuffer.Get(RowNo, 18); // vino (tutti articoli esclusi nazione accessori)
        Evaluate(Dec, ExcelBuffer."Cell Value as Text");
        ExcelBuffer.Get(RowNo, 21); // sconto
        Evaluate(Discount, ExcelBuffer."Cell Value as Text");
        CreateSalesItemLines(SalesHeader, ExcelBuffer, RowNo, VAT);

        ExcelBuffer.Get(RowNo, 22); // spese spedizioni
        Evaluate(Dec, ExcelBuffer."Cell Value as Text");
        CreateSalesLine(SalesHeader, SalesHeader."Gen. Bus. Posting Group", ABS(Dec), 0, 'SPESE SPEDIZIONI', VAT);
        //Commit();
        ExcelBuffer.Get(RowNo, 21); // sconto
        Evaluate(Discount, ExcelBuffer."Cell Value as Text");
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(Discount, SalesHeader);

        //try rounding fix
        ExcelBuffer.Get(RowNo, 14);
        Evaluate(Dec, ExcelBuffer."Cell Value as Text");
        TotalAmtInclVat := -round(dec, 0.01);

        ExcelBuffer.Get(RowNo, 26);
        Evaluate(Dec, ExcelBuffer."Cell Value as Text");
        TotalVAT := -round(dec, 0.01);

        TotalAmount := TotalAmtInclVat - TotalVAT;

        SalesHeader.get(SalesHeader."Document Type", SalesHeader."No.");
        SalesHeader.calcfields("Amount Including VAT", Amount);

        if (SalesHeader.Amount <> TotalAmount) and ((SalesHeader."Amount Including VAT" - SalesHeader.Amount) <> round(TotalVAT, 0.01)) then begin
            Discount += SalesHeader.Amount - TotalAmount;
            SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(Discount, SalesHeader);
            UpdateSalesLineVAT(SalesHeader, ABS(TotalVAT));
        end;
        if (SalesHeader.Amount = TotalAmount) and ((SalesHeader."Amount Including VAT" - SalesHeader.Amount) <> round(TotalVAT, 0.01)) then begin
            //Discount += SalesHeader.Amount - TotalAmount;
            //SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(Discount, SalesHeader);
            UpdateSalesLineVAT(SalesHeader, ABS(TotalVAT));
        end;
        if (SalesHeader.Amount <> TotalAmount) and ((SalesHeader."Amount Including VAT" - SalesHeader.Amount) = round(TotalVAT, 0.01)) then begin
            Discount += SalesHeader.Amount - TotalAmount;
            SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(Discount, SalesHeader);
            UpdateSalesLineVAT(SalesHeader, ABS(TotalVAT));
        end;

        ReleaseSalesDoc.PerformManualRelease(SalesHeader);
        //fix end
        //UpdateSalesLineVAT(SalesHeader, ABS(VAT));

        //Commit();
        //SalesHeader.CalcFields("Amount Including VAT");
        //ExcelBuffer.Get(RowNo, 14); // document total
        //Evaluate(DocumentTotal, ExcelBuffer."Cell Value as Text");
        //Dec := ABS(DocumentTotal) - SalesHeader."Amount Including VAT";   // Rounding
        //If Dec <> 0 then
        //    CreateSalesLine(SalesHeader, SalesHeader."Gen. Bus. Posting Group", Dec, 0, 'ROUNDING', VAT);

        Commit();
        /*SalesHeader.Invoice := true;
        SalesHeader.Ship := true;
        Codeunit.Run(Codeunit::"Sales-Post", SalesHeader);
        Commit();
        if ExcelBuffer.Get(RowNo, 37) then // Paid
            if ExcelBuffer."Cell Value as Text" = 'Yes' then
                PostPayment(SalesHeader, 0)
            else begin
                ExcelBuffer.Get(RowNo, 38);
                Evaluate(Dec, ExcelBuffer."Cell Value as Text");
                if Dec <> 0 then
                    PostPayment(SalesHeader, Dec);
            end;*/
    end;
    //#endregion    
    //#region CreatePurchaseOrder
    local procedure CreatePurchaseOrder(VAR ExcelBuffer: Record "Excel Buffer" temporary; RowNo: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: record Vendor;
        SalesPerson: Record "Salesperson/Purchaser";
        CountryRegion: Record "Country/Region";
        Contact: Record Contact;
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        DocumentType: Text;
        ProductGroup: Code[20];
        Dec: Decimal;
        Discount: Decimal;
        VAT: Decimal;
        DocumentTotal: Decimal;
    begin
        InsertVendor(ExcelBuffer, RowNo, Vendor);
        PurchaseHeader.Init();
        PurchaseHeader.SetHideValidationDialog(True);
        ExcelBuffer.Get(RowNo, 8); // PO/SO number
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."No." := TextToCode20(ExcelBuffer);
        PurchaseHeader."Posting No." := PurchaseHeader."No.";
        PurchaseHeader."Receiving No." := PurchaseHeader."No.";
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        if not PurchaseHeader.Insert(true) then
            exit;
        CreatedDocuments += 1;
        ExcelBuffer.Get(RowNo, 2); // Azienda, cognome, nome
        PurchaseHeader."Buy-from Vendor Name" := TextToText100(ExcelBuffer);
        if ExcelBuffer.Get(RowNo, 3) then // via 1
            PurchaseHeader.Validate("Buy-from Address", ExcelBuffer."Cell Value as Text");
        if ExcelBuffer.Get(RowNo, 4) then // via 2
            PurchaseHeader.Validate("Buy-from Address 2", ExcelBuffer."Cell Value as Text");
        ExcelBuffer.Get(RowNo, 5); // city
        PurchaseHeader.Validate("Buy-from City", ExcelBuffer."Cell Value as Text");
        if ExcelBuffer.Get(RowNo, 6) then // zip
            PurchaseHeader.Validate("Buy-from Post Code", ExcelBuffer."Cell Value as Text");
        ExcelBuffer.Get(RowNo, 7); // country
        CountryRegion.SetRange(Name, ExcelBuffer."Cell Value as Text");
        CountryRegion.FindFirst();
        PurchaseHeader.Validate("Buy-from Country/Region Code", CountryRegion.Code);
        if ExcelBuffer.Get(RowNo, 9) then // Supplier/Client Reference
            PurchaseHeader."Your Reference" := ExcelBuffer."Cell Value as Text";
        ExcelBuffer.Get(RowNo, 11); // date / time
        PurchaseHeader.Validate("Posting Date", GetDate(ExcelBuffer."Cell Value as Text"));
        PurchaseHeader.Validate("Order Date", PurchaseHeader."Posting Date");
        if ExcelBuffer.Get(RowNo, 12) then begin // contatto avu
            if not SalesPerson.Get(ExcelBuffer."Cell Value as Text") then begin
                SalesPerson.Init();
                SalesPerson.Code := TextToCode20(ExcelBuffer);
                SalesPerson.Insert(true);
            end;
            PurchaseHeader.Validate("Purchaser Code", ExcelBuffer."Cell Value as Text");
        end;
        ExcelBuffer.Get(RowNo, 15); // currency
        if not (ExcelBuffer."Cell Value as Text" in [GLSetup."LCY Code", 'NULL']) then
            PurchaseHeader.Validate("Currency Code", ExcelBuffer."Cell Value as Text")
        else
            if PurchaseHeader."Currency Code" <> '' then //fix issue when foreign currency was taken from Vendor
                PurchaseHeader.Validate("Currency Code", '');
        ExcelBuffer.Get(RowNo, 16); // exchange rate
        Evaluate(Dec, ExcelBuffer."Cell Value as Text");
        if Dec = -1 then
            PurchaseHeader.Validate("Currency Factor", 1.126899982)
        else
            PurchaseHeader.Validate("Currency Factor", 1 / Dec);
        if not ExcelBuffer.Get(RowNo, 40) then begin // payment terms
            ExcelBuffer.Get(RowNo, 44); // scadenza1
            if StrLen(ExcelBuffer."Cell Value as Text") > 4 then
                if StrPos(ExcelBuffer."Cell Value as Text", '%') = 0 then
                    PurchaseHeader.Validate("Due Date", GetDate(ExcelBuffer."Cell Value as Text"))
                else
                    PurchaseHeader.Validate("Due Date", GetDate(ExcelBuffer."Cell Value as Text"));
        end else
            PurchaseHeader.Validate("Payment Terms Code", GetPaymentTermsCode(ExcelBuffer."Cell Value as Text"));
        PurchaseHeader."Vendor Invoice No." := PurchaseHeader."No.";
        //if PurchaseHeader."Buy-from Country/Region Code" = 'CH' then
        //    PurchaseHeader.Validate("Vendor Posting Group", 'NAZIONALE')
        //else
        //    PurchaseHeader.Validate("Vendor Posting Group", 'ESTERO');
        PurchaseHeader.Validate("Gen. Bus. Posting Group", PurchaseHeader."Vendor Posting Group");
        ExcelBuffer.Get(RowNo, 26); // iva
        Evaluate(VAT, ExcelBuffer."Cell Value as Text");
        if Contact.Get(PurchaseHeader."Buy-from Vendor No." + '_') then
            PurchaseHeader.Validate("Buy-from Contact No.", PurchaseHeader."Buy-from Vendor No." + '_');
        PurchaseHeader.Validate("Location Code", 'CH');
        PurchaseHeader.Modify(true);

        ExcelBuffer.Get(RowNo, 18); // vino (tutti articoli esclusi nazione accessori)
        Evaluate(Dec, ExcelBuffer."Cell Value as Text");
        if Dec > 0 then
            ProductGroup := 'VINI';

        ExcelBuffer.Get(RowNo, 21); // sconto
        Evaluate(Discount, ExcelBuffer."Cell Value as Text");

        ExcelBuffer.Get(RowNo, 10); // tipo (Fattura/Acquisto/ NDC)
        DocumentType := ExcelBuffer."Cell Value as Text";
        Case DocumentType of
            'SCN finanziaria':
                CreatePurchaseLine(PurchaseHeader, PurchaseHeader."Gen. Bus. Posting Group", Dec, 0, 'IMBALLAGGI', VAT);
            'Acquisto finanziario':
                CreatePurchaseLine(PurchaseHeader, PurchaseHeader."Gen. Bus. Posting Group", Dec, 0, 'EN PRIMEUR', VAT);
            else
                CreatePurchItemLines(PurchaseHeader, ExcelBuffer, RowNo, VAT);
        end;

        ExcelBuffer.Get(RowNo, 22); // spese spedizioni
        Evaluate(Dec, ExcelBuffer."Cell Value as Text");
        CreatePurchaseLine(PurchaseHeader, PurchaseHeader."Gen. Bus. Posting Group", Dec, 0, 'SPESE SPEDIZIONI', VAT);

        ExcelBuffer.Get(RowNo, 23); // imballaggio
        Evaluate(Dec, ExcelBuffer."Cell Value as Text");
        CreatePurchaseLine(PurchaseHeader, PurchaseHeader."Gen. Bus. Posting Group", Dec, 0, 'IMBALLAGGI', VAT);

        ExcelBuffer.Get(RowNo, 24); // assicurazione
        Evaluate(Dec, ExcelBuffer."Cell Value as Text");
        CreatePurchaseLine(PurchaseHeader, PurchaseHeader."Gen. Bus. Posting Group", Dec, 0, 'ASSICURAZIONE', VAT);

        ExcelBuffer.Get(RowNo, 28); // inventory impact EUR
        Evaluate(Dec, ExcelBuffer."Cell Value as Text");

        if DocumentType = 'FatturaSemplice' then
            Error('Row %1, tipo = FatturaSemplice', RowNo);
        if ExcelBuffer.Get(RowNo, 20) and (DocumentType <> 'Acquisto finanziario') then // finanziarie descrizione
            if ExcelBuffer."Cell Value as Text" <> '' then
                Error('Row %1, finanziarie descrizione <> ''''', RowNo);
        Commit();
        ExcelBuffer.Get(RowNo, 21); // sconto
        Evaluate(Discount, ExcelBuffer."Cell Value as Text");
        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(-Discount, PurchaseHeader);
        UpdatePurchaseLineVAT(PurchaseHeader, ABS(VAT));
        //Commit();

        PurchaseHeader.CalcFields("Amount Including VAT");
        ExcelBuffer.Get(RowNo, 14); // document total
        Evaluate(DocumentTotal, ExcelBuffer."Cell Value as Text");
        Dec := DocumentTotal - PurchaseHeader."Amount Including VAT";
        If Dec <> 0 then
            CreatePurchaseLine(PurchaseHeader, PurchaseHeader."Gen. Bus. Posting Group", Dec, 0, 'ROUNDING', VAT);

        Commit();
        /*PurchaseHeader.Invoice := true;
        PurchaseHeader.Receive := true;
        Codeunit.Run(Codeunit::"Purch.-Post", PurchaseHeader);
        Commit();

        if ExcelBuffer.Get(RowNo, 37) then // Paid
            if ExcelBuffer."Cell Value as Text" = 'Yes' then
                PostPayment(PurchaseHeader, 0)
            else begin
                ExcelBuffer.Get(RowNo, 38);
                Evaluate(Dec, ExcelBuffer."Cell Value as Text");
                if Dec <> 0 then
                    PostPayment(PurchaseHeader, Dec);
            end;*/
    end;

    local procedure CreatePurchItemLines(PurchaseHeader: Record "Purchase Header"; var ExcelBuffer: Record "Excel Buffer" temporary; RowNo: Integer; VAT: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        Dec: Decimal;
        Finish: Boolean;
        LineNo: Integer;
        Int: Integer;
    begin
        repeat
            if not ExcelBuffer.Get(RowNo, 8) then // PO/SO number
                Finish := true;
            if not Finish and (UPPERCASE(ExcelBuffer."Cell Value as Text") = PurchaseHeader."No.") then begin
                ExcelBuffer.Get(RowNo, 29); // ID vino completo
                if Item.Get(ExcelBuffer."Cell Value as Text") then begin
                    //if Item."VAT Prod. Posting Group" <> 'GOODS (STANDARD)' then begin
                    //    Item.Validate("VAT Prod. Posting Group", 'GOODS (STANDARD)');
                    //    Item.Modify(true);
                    //end;

                    PurchaseLine.Init();
                    PurchaseLine."Document Type" := PurchaseHeader."Document Type";
                    PurchaseLine."Document No." := PurchaseHeader."No.";
                    LineNo += 10000;
                    PurchaseLine."Line No." := LineNo;
                    PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
                    PurchaseLine.Validate("No.", Item."No.");
                    PurchaseLine.Validate("Location Code", 'CH');
                    if VAT = 0 then
                        PurchaseLine.Validate("VAT Prod. Posting Group", 'NO VAT')
                    else
                        if PurchaseLine."VAT bus. Posting Group" = 'ESTERO' then
                            PurchaseLine.Validate("VAT Prod. Posting Group", 'GOODS (VAT)');

                    ExcelBuffer.Get(RowNo, 30); // Qty Vino
                    Evaluate(Int, ExcelBuffer."Cell Value as Text");
                    PurchaseLine.Validate(Quantity, ABS(Int));
                    ExcelBuffer.Get(RowNo, 31); // PA vino
                    Evaluate(Dec, ExcelBuffer."Cell Value as Text");
                    PurchaseLine.Validate("Direct Unit Cost", ABS(Dec));
                    PurchaseLine.Insert(True);
                end;
            end else
                Finish := true;
            RowNo += 1;
        until Finish;
    end;

    local procedure CreatePurchaseLine(PurchaseHeader: Record "Purchase Header"; BusGroup: code[20]; Amount: Decimal; Discount: Decimal; ProdGroup: code[20]; Vat: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        Account: Code[20];
        LineNo: Integer;
    begin
        if Amount = 0 then
            exit;

        case ProdGroup of
            /*'ACCESSORI':
                Account := '4601';*/
            'SPESE SPEDIZIONI':
                begin
                    /* old mapping
                    if PurchaseHeader."Currency Code" = 'CHF' then
                        Account := '4721'
                    else
                        Account := '4723';
                    */
                    case PurchaseHeader."Buy-from Country/Region Code" of
                        'CH':
                            Account := '4721';
                        'GB':
                            Account := '4722';
                        'FR':
                            Account := '4723';
                        else
                            Account := '4724'
                    end;

                end;

            'IMBALLAGGI':
                Account := '4663';
            'ASSICURAZIONE':
                Account := '6300';
            'EN PRIMEUR':
                Account := '4661';
            'ROUNDING':
                Account := '4901';
            else
                Error('Purchase %1', ProdGroup);
        end;
        PurchaseLine.SETRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindLast() then
            LineNo := PurchaseLine."Line No.";

        PurchaseLine.Init();
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Line No." := LineNo + 10000;
        PurchaseLine.Validate(Type, PurchaseLine.Type::"G/L Account");
        PurchaseLine.Validate("No.", Account);
        PurchaseLine.Validate(Quantity, 1);

        PurchaseLine.Validate("Direct Unit Cost", Amount);
        //PurchaseLine.Validate("Gen. Prod. Posting Group", ProdGroup);
        //PurchaseLine.Validate("VAT Prod. Posting Group", 'GOODS (STANDARD)');
        if VAT = 0 then
            PurchaseLine.Validate("VAT Prod. Posting Group", 'NO VAT');
        IF ProdGroup <> 'ROUNDING' THEN
            PurchaseLine.Description := ProdGroup;
        PurchaseLine.Insert(True);
    end;

    local procedure CreatePurchaseLineCost(DocumentType: Option; DocumentNo: code[20]; Amount: Decimal; ProductGroup: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        LineNo: Integer;
    begin
        if Amount = 0 then
            exit;

        PurchaseLine.SETRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        if PurchaseLine.FindLast() then
            LineNo := PurchaseLine."Line No.";

        PurchaseLine.Init();
        PurchaseLine."Document Type" := DocumentType;
        PurchaseLine."Document No." := DocumentNo;
        PurchaseLine."Line No." := LineNo + 10000;
        PurchaseLine.Validate(Type, PurchaseLine.Type::" ");
        PurchaseLine.Validate("No.", 'COST');
        PurchaseLine.Validate(Description, Format(Amount));
        PurchaseLine."Posting Group" := ProductGroup;
        PurchaseLine.Insert(True);
    end;

    local procedure UpdatePurchaseLineVAT(PurchHeader: Record "Purchase Header"; VAT: Decimal)
    var
        PurchLine: Record "Purchase Line";
        TempPurchLine: Record "Purchase Line" temporary;
        VATAmountLine: Record "VAT Amount Line" temporary;
        PurchasePost: Codeunit "Purch.-Post";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
        VATAmount: Decimal;
    begin
        PurchasePost.GetPurchLines(PurchHeader, TempPurchLine, 1);
        TempPurchLine.CalcVATAmountLines(0, PurchHeader, TempPurchLine, VATAmountLine);
        TempPurchLine.UpdateVATOnLines(0, PurchHeader, TempPurchLine, VATAmountLine);
        VATAmount := VATAmountLine.GetTotalVATAmount();
        if Round(VATAmount, 0.01) = Round(VAT, 0.01) then
            exit;

        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange("VAT Identifier", '7.7%');
        PurchLine.FindFirst();
        PurchLine."VAT Difference" := Round(VAT, 0.01) - Round(VATAmount, 0.01);
        PurchLine.Modify();
        ReleasePurchDoc.CalcAndUpdateVATOnLines(PurchHeader, PurchLine);
    end;

    local procedure PostPayment(PurchaseHeader: Record "Purchase Header"; Amount: Decimal)
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        LineNo: Integer;
    begin
        GenJnlTemplate.Get('PAGAM');
        GenJnlBatch.Get(GenJnlTemplate.Name, 'GENERALE');
        GenJournalLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        //GenJournalLine.DeleteAll(true);
        if GenJournalLine.FindLast() then
            LineNo := GenJournalLine."Line No." + 10000
        else
            LineNo := 10000;

        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := GenJnlBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJnlBatch.Name;
        GenJournalLine."Line No." := LineNo;
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Credit Memo" then
            GenJournalLine."Document Type" := GenJournalLine."Document Type"::Refund
        else
            GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment;
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Vendor;
        GenJournalLine."Source Code" := GenJnlTemplate."Source Code";
        GenJournalLine."Reason Code" := GenJnlBatch."Reason Code";
        GenJournalLine."Journal Batch Id" := GenJnlBatch.Id;
        GenJournalLine.Insert(true);

        GenJournalLine.Validate("Posting Date", DMY2Date(31, 12, 2018));
        GenJournalLine.Validate("Document No.", PurchaseHeader."No.");
        GenJournalLine.Validate("External Document No.", PurchaseHeader."No.");
        GenJournalLine.Validate("Account No.", PurchaseHeader."Buy-from Vendor No.");
        GenJournalLine.Validate("Currency Code", PurchaseHeader."Currency Code");
        GenJournalLine."Currency Factor" := PurchaseHeader."Currency Factor";
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        if PurchaseHeader."Currency Code" = '' then
            GenJournalLine.Validate("Bal. Account No.", 'UBS EUR')
        else
            GenJournalLine.Validate("Bal. Account No.", 'UBS ' + PurchaseHeader."Currency Code");
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Credit Memo" then
            GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::"Credit Memo")
        else
            GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", PurchaseHeader."No.");
        if Amount = 0 then begin
            VendorLedgerEntry.SetCurrentKey("Vendor No.", Open, Positive, "Due Date");
            VendorLedgerEntry.SetRange("Vendor No.", GenJournalLine."Account No.");
            VendorLedgerEntry.SetRange(Open, true);
            VendorLedgerEntry.SetRange("Document Type", GenJournalLine."Applies-to Doc. Type");
            VendorLedgerEntry.SetRange("Document No.", GenJournalLine."Applies-to Doc. No.");
            VendorLedgerEntry.FindFirst();
            VendorLedgerEntry.CalcFields("Remaining Amount");
            Amount := -VendorLedgerEntry."Remaining Amount";
        end;
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Modify(true);
        Commit();
        //Codeunit.Run(Codeunit::"Gen. Jnl.-Post", GenJournalLine);
        //Commit();
    end;
    //#endregion
    //#region CreatePurchaseCreditMemo
    local procedure CreatePurchaseCreditMemo(VAR ExcelBuffer: Record "Excel Buffer" temporary; RowNo: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        SalesPerson: Record "Salesperson/Purchaser";
        CountryRegion: Record "Country/Region";
        Contact: Record Contact;
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        Dec: Decimal;
        Discount: Decimal;
        VAT: Decimal;
        DocumentTotal: Decimal;
    begin
        InsertVendor(ExcelBuffer, RowNo, Vendor);
        PurchaseHeader.Init();
        PurchaseHeader.SetHideValidationDialog(true);
        ExcelBuffer.Get(RowNo, 8); // PO/SO number
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::"Credit Memo";
        PurchaseHeader."No." := TextToCode20(ExcelBuffer);
        PurchaseHeader."Posting No." := PurchaseHeader."No.";
        PurchaseHeader."Vendor Cr. Memo No." := PurchaseHeader."No.";
        PurchaseHeader."Return Shipment No." := PurchaseHeader."No.";
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        if not PurchaseHeader.Insert(true) then
            exit;
        CreatedDocuments += 1;
        ExcelBuffer.Get(RowNo, 2); // Azienda, cognome, nome
        PurchaseHeader."Buy-from Vendor Name" := TextToText100(ExcelBuffer);
        if ExcelBuffer.Get(RowNo, 3) then // via 1
            PurchaseHeader.Validate("Buy-from Address", ExcelBuffer."Cell Value as Text");
        if ExcelBuffer.Get(RowNo, 4) then // via 2
            PurchaseHeader.Validate("Buy-from Address 2", ExcelBuffer."Cell Value as Text");
        ExcelBuffer.Get(RowNo, 5); // city
        PurchaseHeader.Validate("Buy-from City", ExcelBuffer."Cell Value as Text");
        if ExcelBuffer.Get(RowNo, 6) then // zip
            PurchaseHeader.Validate("Buy-from Post Code", ExcelBuffer."Cell Value as Text");
        ExcelBuffer.Get(RowNo, 7); // country
        CountryRegion.SetRange(Name, ExcelBuffer."Cell Value as Text");
        CountryRegion.FindFirst();
        PurchaseHeader.Validate("Buy-from Country/Region Code", CountryRegion.Code);
        if ExcelBuffer.Get(RowNo, 9) then // Supplier/Client Reference
            PurchaseHeader."Your Reference" := ExcelBuffer."Cell Value as Text";
        ExcelBuffer.Get(RowNo, 11); // date / time
        PurchaseHeader.Validate("Posting Date", GetDate(ExcelBuffer."Cell Value as Text"));
        PurchaseHeader.Validate("Order Date", PurchaseHeader."Posting Date");
        if ExcelBuffer.Get(RowNo, 12) then begin // contatto avu
            if not SalesPerson.Get(ExcelBuffer."Cell Value as Text") then begin
                SalesPerson.Init();
                SalesPerson.Code := TextToCode20(ExcelBuffer);
                SalesPerson.Insert(true);
            end;
            PurchaseHeader.Validate("Purchaser Code", ExcelBuffer."Cell Value as Text");
        end;
        ExcelBuffer.Get(RowNo, 15); // currency
        if not (ExcelBuffer."Cell Value as Text" in [GLSetup."LCY Code", 'NULL']) then
            PurchaseHeader.Validate("Currency Code", ExcelBuffer."Cell Value as Text")
        else
            if PurchaseHeader."Currency Code" <> '' then //fix issue when foreign currency was taken from Vendor
                PurchaseHeader.Validate("Currency Code", '');
        ExcelBuffer.Get(RowNo, 16); // exchange rate
        Evaluate(Dec, ExcelBuffer."Cell Value as Text");
        PurchaseHeader.Validate("Currency Factor", 1 / Dec);
        if not ExcelBuffer.Get(RowNo, 40) then begin // payment terms
            ExcelBuffer.Get(RowNo, 44); // scadenza1
            PurchaseHeader.Validate("Due Date", GetDate(ExcelBuffer."Cell Value as Text"));
        end else
            PurchaseHeader.Validate("Payment Terms Code", GetPaymentTermsCode(ExcelBuffer."Cell Value as Text"));
        PurchaseHeader."Vendor Invoice No." := PurchaseHeader."No.";
        //if PurchaseHeader."Buy-from Country/Region Code" = 'CH' then
        //    PurchaseHeader.Validate("Vendor Posting Group", 'NAZIONALE')
        //else
        //    PurchaseHeader.Validate("Vendor Posting Group", 'ESTERO');
        PurchaseHeader.Validate("Gen. Bus. Posting Group", PurchaseHeader."Vendor Posting Group");

        ExcelBuffer.Get(RowNo, 26); // iva
        Evaluate(VAT, ExcelBuffer."Cell Value as Text");

        if Contact.Get(PurchaseHeader."Buy-from Vendor No." + '_') then
            PurchaseHeader.Validate("Buy-from Contact No.", PurchaseHeader."Buy-from Vendor No." + '_');
        PurchaseHeader.Validate("Location Code", 'CH');
        PurchaseHeader.Modify(true);

        ExcelBuffer.Get(RowNo, 18); // vino (tutti articoli esclusi nazione accessori)
        Evaluate(Dec, ExcelBuffer."Cell Value as Text");
        ExcelBuffer.Get(RowNo, 21); // sconto
        Evaluate(Discount, ExcelBuffer."Cell Value as Text");

        CreatePurchItemLines(PurchaseHeader, ExcelBuffer, RowNo, VAT);

        ExcelBuffer.Get(RowNo, 22); // spese spedizioni
        Evaluate(Dec, ExcelBuffer."Cell Value as Text");
        CreatePurchaseLine(PurchaseHeader, PurchaseHeader."Gen. Bus. Posting Group", Dec, 0, 'SPESE SPEDIZIONI', VAT);

        ExcelBuffer.Get(RowNo, 23); // imballaggio
        Evaluate(Dec, ExcelBuffer."Cell Value as Text");
        CreatePurchaseLine(PurchaseHeader, PurchaseHeader."Gen. Bus. Posting Group", Dec, 0, 'IMBALLAGGI', VAT);

        ExcelBuffer.Get(RowNo, 24); // assicurazione
        Evaluate(Dec, ExcelBuffer."Cell Value as Text");
        CreatePurchaseLine(PurchaseHeader, PurchaseHeader."Gen. Bus. Posting Group", Dec, 0, 'ASSICURAZIONE', VAT);

        ExcelBuffer.Get(RowNo, 10); // tipo (Fattura/Acquisto/ NDC)
        if ExcelBuffer."Cell Value as Text" = 'FatturaSemplice' then
            Error('Row %1, tipo = FatturaSemplice', RowNo);
        if ExcelBuffer.Get(RowNo, 20) then // finanziarie descrizione
            if ExcelBuffer."Cell Value as Text" <> '' then
                Error('Row %1, finanziarie descrizione <> ''''', RowNo);
        Commit();
        ExcelBuffer.Get(RowNo, 21); // sconto
        Evaluate(Discount, ExcelBuffer."Cell Value as Text");
        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(-Discount, PurchaseHeader);
        UpdatePurchaseLineVAT(PurchaseHeader, ABS(VAT));
        //Commit();

        PurchaseHeader.CalcFields("Amount Including VAT");
        ExcelBuffer.Get(RowNo, 14); // document total
        Evaluate(DocumentTotal, ExcelBuffer."Cell Value as Text");
        Dec := ABS(DocumentTotal) - PurchaseHeader."Amount Including VAT";
        If Dec <> 0 then
            CreatePurchaseLine(PurchaseHeader, PurchaseHeader."Gen. Bus. Posting Group", Dec, 0, 'ROUNDING', VAT);

        Commit();
        /*PurchaseHeader.Invoice := true;
        PurchaseHeader.Receive := true;
        Codeunit.Run(Codeunit::"Purch.-Post", PurchaseHeader);
        Commit();
        if ExcelBuffer.Get(RowNo, 37) then // Paid
            if ExcelBuffer."Cell Value as Text" = 'Yes' then
                PostPayment(PurchaseHeader, 0)
            else begin
                ExcelBuffer.Get(RowNo, 38);
                Evaluate(Dec, ExcelBuffer."Cell Value as Text");
                if Dec <> 0 then
                    PostPayment(PurchaseHeader, Dec);
            end;*/
    end;
    //#endregion
    //#region Other
    local procedure GetProductGroup(Value: Text): Code[20]
    begin
        Value := UpperCase(Value);
        if (StrPos(Value, 'TRANSPORT') > 0) or (StrPos(Value, 'SHIPMENT') > 0) or (StrPos(Value, 'DELIVERY') > 0) or (StrPos(Value, 'LIEFERKOSTEN') > 0) or
           (StrPos(Value, 'TRASPORT') > 0)
        then
            exit('SPESE SPEDIZIONI');
        if (StrPos(Value, 'BANK GUARANTEE') > 0) or (StrPos(Value, 'BANK GURANTEE') > 0) then
            exit('GARANZIA BANCARIA');
        if StrPos(Value, 'CERTIFICAT') > 0 then
            exit('CERTIFICATO');
        if StrPos(Value, 'LATE INTEREST') > 0 then
            exit('INTERESSI DI MORA');

        Error('Posting group not found for ''%1''.', Value);
    end;

    local procedure GetPaymentTermsCode(Value: Text): Code[10]
    begin
        case Value of
            '10 days from Invoice':
                exit('10 GIORNI');
            '10 days net of invoice':
                exit('10 GIORNI');
            '30 days from Invoice':
                exit('30 GIORNI');
            '30 days from invoice and prior to collect':
                exit('30 GIORNI');
            '30 days from Invoice and prior to Collection':
                exit('30 GIORNI');
            '30 days net of invoice':
                exit('30 GIORNI');
            '45 days net of invoice':
                exit('45 GIORNI');
            '60 days net of invoice':
                exit('60 GIORNI');
            '90 days net of invoice':
                exit('90 GIORNI');
            'On receipt of Invoice':
                exit('1 GIORNO');
            'On receipt of Invoice and prior to Collection':
                exit('1 GIORNO');
            'On receipt of the goods':
                exit('5G SPED');
            'Payment due after collection':
                exit('1G SPED');
            'Payment due at collection':
                exit('10 GIORNI');
            'Payment due at delivery':
                exit('5G SPED');
            'Payment due in advance':
                exit('1 GIORNO');
        end;
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
        if StrLen(Text) = 8 then
            Evaluate(Year, CopyStr(Text, 5, 4))
        else
            Evaluate(Year, '20' + CopyStr(Text, 5, 2));
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
    //#endregion
}