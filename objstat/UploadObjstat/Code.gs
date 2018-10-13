function doGet() {
    return HtmlService.createHtmlOutputFromFile('index')
        .setSandboxMode(HtmlService.SandboxMode.NATIVE);
}

function sheetFromFile(ss, name, file, doFreeze)
{
    var csv = Utilities.parseCsv(file.getDataAsString(), "\t");
    var numRows = csv.length;
    var numCols = csv[0].length;

    var sheet = ss.insertSheet(name);
    doFreeze = typeof doFreeze === 'undefined' ? true : doFreeze;

    sheet.getRange(1, 1, numRows, numCols).setValues(csv);
    for (var i = 0; i < numCols; i++) {
        sheet.autoResizeColumn(i + 1);
    }

    if (doFreeze) {
        sheet.setFrozenColumns(2);
        sheet.setFrozenRows(1);
    }

    return sheet;
}

function updateOutput(output, isError) {
    if (isError) {
        output = "ERROR: " + output;
    }

    Logger.log(output);
}

function processForm(formObject) {
    updateOutput("Unziping " + formObject.zipFile);
    var files = Utilities.unzip(formObject.zipFile);
    var numFiles = files.length;
    updateOutput("Unziped " + numFiles + " files");

    var itemIndices = [];
    var itemNames = [];
    var infoInd = -1;
    var monsInd = -1;
    var featInd = -1;

    for (var i = 0; i < numFiles; i++) {
        var name = files[i].getName()
        name = name.replace("objstat_", "").replace(".txt", "");
        if (name == "Info") {
            infoInd = i;
        } else if (name == "Monsters") {
            monsInd = i;
        } else if (name == "Features") {
            featInd = i;
        } else {
            itemIndices[itemIndices.length] = i;
            itemNames[itemNames.length] = name;
        }
    }
    if (infoInd < 0) {
        upudateOutput("Unable to find Info file", true);
        return;
    } else if (monsInd < 0) {
        upudateOutput("Unable to find Monsters file", true);
        return;
    } else if (featInd < 0) {
        upudateOutput("Unable to find Features file", true);
        return;
    }

    // Find the ObjStat folder.
    var folders = DriveApp.getFoldersByName("ObjStat");
    var folder;
    while (folders.hasNext()) {
        folder = folders.next();
        break;
    }
    var ss = SpreadsheetApp.create(formObject.ssName);
    var ssFile = DriveApp.getFileById(ss.getId());
    folder.addFile(ssFile);
    DriveApp.getRootFolder().removeFile(ssFile);

    var emptySheet = ss.getActiveSheet();
    updateOutput("Created Spreadsheet" + formObject.ssName);

    var sheet = sheetFromFile(ss, "Info", files[infoInd], false);
    updateOutput("Parsed " + sheet.getLastRow() + " rows and "
                 + sheet.getLastColumn() + " columns from Info");

    sheet = sheetFromFile(ss, "Monsters", files[monsInd]);
    updateOutput("Parsed " + sheet.getLastRow() + " rows and "
                 + sheet.getLastColumn() + " columns from Monsters");

    sheet = sheetFromFile(ss, "Features", files[featInd]);
    updateOutput("Parsed " + sheet.getLastRow() + " rows and "
                 + sheet.getLastColumn() + " columns from Features");

    ss.setActiveSheet(emptySheet);
    ss.deleteActiveSheet();
    ss.setActiveSheet(sheet);

    function item_sort(a, b) {
        return itemNames[a] < itemNames[b] ? -1 : 1;
    }
    itemIndices = itemIndices.sort(item_sort);

    var numTables = itemIndices.length;
    for (var i = 0; i < numTables; i++) {
        sheet = sheetFromFile(ss, itemNames[i], files[itemIndices[i]]);
        updateOutput("Parsed " + sheet.getLastRow() + " rows and "
                     + sheet.getLastColumn() + " columns from " + itemNames[i]);
    }
    updateOutput("Sheet created at " + ss.getUrl());

    return ss.getUrl();
}
