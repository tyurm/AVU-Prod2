report 82001 "AVU Import Contacts"
{
    Caption = 'Import Contacts';
    UsageCategory = Administration;
    ApplicationArea = All;
    ProcessingOnly = true;

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
            SheetName := 'Foglio1';
        end;
    }

    var
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

        ProcessRecords(ExcelBuffer);
        Message(FinishedLbl);
    end;

    local procedure ProcessRecords(var ExcelBuffer: Record "Excel Buffer" temporary)
    var
        ExcelBuffer2: Record "Excel Buffer" temporary;
        Contact: Record Contact;
        Contact2: Record Contact;
        Window: Dialog;
        Name: Text;
        HasPerson: Boolean;
    begin
        Contact.deleteall(true);
        ExcelBuffer2.Copy(ExcelBuffer, true);

        Window.Open(ProcessingLbl);
        ExcelBuffer.SetRange("Column No.", 1);
        ExcelBuffer.SetFilter("Row No.", '>%1', RowsToSkip);
        if ExcelBuffer.FindSet() then
            repeat
                Window.Update(1, ExcelBuffer."Cell Value as Text");
                Clear(Contact);
                if not Contact.get(ExcelBuffer."Cell Value as Text") then begin
                    Name := '';
                    if ExcelBuffer2.Get(ExcelBuffer."Row No.", 2) then // nomeDitta
                        Name := ExcelBuffer2."Cell Value as Text"
                    else
                        Name := GetContactName(ExcelBuffer2, ExcelBuffer."Row No.");
                    ExcelBuffer2.Get(ExcelBuffer."Row No.", 18); // isSecondo
                    if ExcelBuffer2."Cell Value as Text" = 'secondario' then begin
                        Contact.Reset();
                        Contact.SetRange(Name, GetContactName(ExcelBuffer2, ExcelBuffer."Row No."));
                        if Contact.Count() <> 1 then
                            error('Several contacts %1 %2', ExcelBuffer."Row No.", GetContactName(ExcelBuffer2, ExcelBuffer."Row No."));
                        Contact.FindFirst();
                        Contact.Testfield("Company No.");

                        Contact2.Init();
                        Contact2."No." := TextToCode20(ExcelBuffer);
                        Contact2.Validate(Type, Contact2.Type::Person);
                        Contact2.Validate(Name, GetContactName(ExcelBuffer2, ExcelBuffer."Row No."));
                        Contact2."Company No." := Contact."Company No.";
                        Contact2."Company Name" := Contact."Company Name";
                        UpdateFields(ExcelBuffer2, Contact2, ExcelBuffer."Row No.");
                        Contact2.Insert(true);
                    end else begin
                        Contact.Init();
                        Contact."No." := TextToCode20(ExcelBuffer);
                        Contact.Validate(Type, Contact.Type::Company);
                        Contact.Validate(Name, Name);
                        Contact."Company No." := Contact."No.";
                        UpdateFields(ExcelBuffer2, Contact, ExcelBuffer."Row No.");
                        if ExcelBuffer2.Get(ExcelBuffer."Row No.", 27) then // ValutaAcquisto
                            if not (ExcelBuffer2."Cell Value as Text" in ['EUR', 'NULL']) then
                                Contact.Validate("Currency Code", ExcelBuffer2."Cell Value as Text");
                        if ExcelBuffer2.Get(ExcelBuffer."Row No.", 37) then // IVA
                            Contact."VAT Registration No." := ExcelBuffer2."Cell Value as Text";
                        Contact.Insert(true);
                        ExcelBuffer."Cell Value as Text" := CopyStr(ExcelBuffer."Cell Value as Text" + '_', 1, 250);

                        HasPerson := ExcelBuffer2.Get(ExcelBuffer."Row No.", 4) or ExcelBuffer2.Get(ExcelBuffer."Row No.", 5); // nome cognome
                        if HasPerson then begin // nome
                            Contact2.Init();
                            Contact2."No." := TextToCode20(ExcelBuffer);
                            Contact2.Validate(Type, Contact2.Type::Person);
                            Contact2.Validate(Name, GetContactName(ExcelBuffer2, ExcelBuffer."Row No."));
                            if Contact."Company No." <> '' then begin
                                Contact2."Company No." := Contact."Company No.";
                                Contact2."Company Name" := Contact."Company Name";
                            end;
                            UpdateFields(ExcelBuffer2, Contact2, ExcelBuffer."Row No.");
                            Contact2.Insert(true);
                        end;
                    end;
                end;
            until (ExcelBuffer.Next() = 0);// or (ExcelBuffer."Row No." > 100);
        Window.Close();
    end;

    local procedure GetContactName(var ExcelBuffer: Record "Excel Buffer" temporary; RowNo: Integer): Text
    var
        Name: Text;
    begin
        if ExcelBuffer.Get(RowNo, 3) then // intestazione
            if ExcelBuffer."Cell Value as Text" in ['Dr', 'Mr', 'Mrs', 'Ms'] then
                Name := Name + ' ' + ExcelBuffer."Cell Value as Text";
        if ExcelBuffer.Get(RowNo, 4) then // nome
            Name := Name + ' ' + ExcelBuffer."Cell Value as Text";
        if ExcelBuffer.Get(RowNo, 5) then // cognome
            Name := Name + ' ' + ExcelBuffer."Cell Value as Text";
        exit(Name);
    end;

    local procedure UpdateFields(var ExcelBuffer: Record "Excel Buffer" temporary; var Contact: Record Contact; RowNo: Integer)
    var
        SalesPerson: Record "Salesperson/Purchaser";
        CountryRegion: Record "Country/Region";
    begin
        if ExcelBuffer.Get(RowNo, 3) and (ExcelBuffer."Cell Value as Text" <> 'NULL') then // intestazione
            Contact."AVU Title" := TextToText30(ExcelBuffer);
        if ExcelBuffer.Get(RowNo, 7) then // idPersona
            Contact."AVU Person ID" := TextToText30(ExcelBuffer);
        if ExcelBuffer.Get(RowNo, 8) then // tipoContatto
            Contact."AVU Contact Type" := TextToText30(ExcelBuffer);
        if ExcelBuffer.Get(RowNo, 9) and (ExcelBuffer."Cell Value as Text" <> 'NULL') then begin // contattoArvi
            if not SalesPerson.Get(ExcelBuffer."Cell Value as Text") then begin
                SalesPerson.Init();
                SalesPerson.Code := TextToCode20(ExcelBuffer);
                SalesPerson.Insert(true);
            end;
            Contact.Validate("Salesperson Code", ExcelBuffer."Cell Value as Text");
        end;
        if ExcelBuffer.Get(RowNo, 13) and (ExcelBuffer."Cell Value as Text" <> 'NULL') then // telefono
            if StrLen(ExcelBuffer."Cell Value as Text") < 31 then // TODO
                Contact.Validate("Phone No.", ExcelBuffer."Cell Value as Text");
        if ExcelBuffer.Get(RowNo, 14) and (StrLen(ExcelBuffer."Cell Value as Text") < 31) and (ExcelBuffer."Cell Value as Text" <> 'NULL') then // cellulare
            Contact.Validate("Mobile Phone No.", ExcelBuffer."Cell Value as Text");
        if ExcelBuffer.Get(RowNo, 15) and (StrLen(ExcelBuffer."Cell Value as Text") < 31) and (ExcelBuffer."Cell Value as Text" <> 'NULL') then // fax
            Contact.Validate("Fax No.", ExcelBuffer."Cell Value as Text");
        if ExcelBuffer.Get(RowNo, 16) then // email
            if (StrPos(ExcelBuffer."Cell Value as Text", '@') > 0) and (StrLen(ExcelBuffer."Cell Value as Text") > 3) then
                //Contact.Validate("E-Mail", DelChr(ExcelBuffer."Cell Value as Text", '=', ' ')); // TODO
                Contact."E-Mail" := CopyStr(DelChr(ExcelBuffer."Cell Value as Text", '=', ' '), 1, 80);
        if ExcelBuffer.Get(RowNo, 17) and (ExcelBuffer."Cell Value as Text" <> 'NULL') then // mansione
            Contact."Job Title" := TextToText30(ExcelBuffer);
        if ExcelBuffer.Get(RowNo, 19) then // lingua
            case ExcelBuffer."Cell Value as Text" of
                'Francese':
                    Contact.Validate("Language Code", 'FRA');
                'Inglese':
                    Contact.Validate("Language Code", 'ENU');
                'Italiano':
                    Contact.Validate("Language Code", 'ITA');
                'Tedesco':
                    Contact.Validate("Language Code", 'DEU');
                'Spagnolo':
                    Contact.Validate("Language Code", 'ESP');
                'Portoghese':
                    Contact.Validate("Language Code", 'PTG');
                'Giapponese':
                    Contact.Validate("Language Code", 'JPN');
                'Russo':
                    Contact.Validate("Language Code", 'RUS');
            end;
        if ExcelBuffer.Get(RowNo, 20) then // fornitoreSpeciale
            Contact."AVU Special Supplier" := ExcelBuffer."Cell Value as Text" = 'si';
        if ExcelBuffer.Get(RowNo, 21) then // indirizzo1
            Contact.Validate(Address, ExcelBuffer."Cell Value as Text");
        if ExcelBuffer.Get(RowNo, 22) then // indirizzo2
            Contact.Validate("Address 2", CopyStr(ExcelBuffer."Cell Value as Text", 1, 50));
        if ExcelBuffer.Get(RowNo, 23) then // cap
            Contact."Post Code" := TextToCode20(ExcelBuffer);
        if ExcelBuffer.Get(RowNo, 24) then // localita
            Contact.City := CopyStr(ExcelBuffer."Cell Value as Text", 1, 30);
        if ExcelBuffer.Get(RowNo, 26) and (ExcelBuffer."Cell Value as Text" <> 'NULL') then begin // codiceNazione
            if not CountryRegion.get(ExcelBuffer."Cell Value as Text") then begin
                CountryRegion.INIT();
                CountryRegion.Code := ExcelBuffer."Cell Value as Text";
                CountryRegion.INSErt(true);
            end;
            Contact.Validate("Country/Region Code", ExcelBuffer."Cell Value as Text");
        End;
    end;

    local procedure TextToCode20(ExcelBuffer: Record "Excel Buffer"): Code[20]
    begin
        if StrLen(ExcelBuffer."Cell Value as Text") > 20 then
            Error(LengthErrorLbl, ExcelBuffer."Cell Value as Text", 20, ExcelBuffer."Row No.");
        Exit(CopyStr(ExcelBuffer."Cell Value as Text", 1, 20));
    end;

    local procedure TextToText30(ExcelBuffer: Record "Excel Buffer"): Text[30]
    begin
        if StrLen(ExcelBuffer."Cell Value as Text") > 30 then
            Error(LengthErrorLbl, ExcelBuffer."Cell Value as Text", 30, ExcelBuffer."Row No.");
        Exit(CopyStr(ExcelBuffer."Cell Value as Text", 1, 30));
    end;
}