import xlsx from 'xlsx'
import path from 'path'
import { ethers } from 'hardhat'
import fs from 'fs';

export function gasUsedFunctions (_contract: string, _fun: string, _detail: string, _tx:any) {
    let data = {
        "Contract": _contract,
        "Name": _fun,
        "Tx": '',
        "Description": _detail,
        "GasUsed": '',
        };

    if( _tx != null && (
        (_tx.deployTransaction != null && _tx.deployTransaction.hash != null)
        || _tx.hash !=null || _tx.transactionHash !=null )
      ) {

        let hash = _tx.hash;

        if(_tx.deployTransaction != null && _tx.deployTransaction.hash!=null) hash = _tx.deployTransaction.hash;
        if(_tx.transactionHash != null && _tx.transactionHash!=null) hash = _tx.transactionHash;
        data.Tx = hash

        if (_tx.gasUsed != null) data.GasUsed = _tx.gasUsed.toString()
    }
    return data
  }

  export const exportLogsToExcel = (transactions: Array<any>, workSheetColumnNames: any, workSheetName: any, filePath:string, gasPrice: number) => {
    const data = transactions.map(transaction => {
        let usd = transaction.GasUsed * gasPrice
        return [
            transaction.Contract,
            transaction.Name,
            '',
            transaction.Description,
            transaction.GasUsed,
            ethers.utils.formatEther(ethers.BigNumber.from(""+usd).mul(ethers.BigNumber.from("1000000000")))
            ];
    });
    exportExcel(data, workSheetColumnNames, workSheetName, filePath);
}

const exportExcel = (data: any, workSheetColumnNames: any, workSheetName:string, filePath:string) => {
    const workBook = xlsx.utils.book_new();
    const workSheetData = [
        workSheetColumnNames,
        ...data
    ];

    //console.log(workSheetData);

    const workSheet = xlsx.utils.aoa_to_sheet(workSheetData);
    xlsx.utils.book_append_sheet(workBook, workSheet, workSheetName);
    xlsx.writeFile(workBook, path.resolve(filePath));
}


export const exportLogs = (transactions: Array<any>, filePath:string, gasPrice: number) => {
    const data = transactions.map(transaction => {
        let usd = transaction.GasUsed * gasPrice
        return [
            transaction.Contract,
            transaction.Name,
            '',
            transaction.Description,
            transaction.GasUsed,
            ethers.utils.formatEther(ethers.BigNumber.from(""+usd).mul(ethers.BigNumber.from("1000000000")))
            ];
    });
    exportLog(data, filePath);
}


const exportLog = (data: any, filePath:string) => {
    const txtHeader = 'Contract,Name,Tx,Description,GasUsed\n'
    let result = txtHeader;
    // console.log(data)
    for (let i = 0; i < data.length; i++) {
        let stringified = Object.values(data[i]).join(',') + '\n';
        result += stringified;
    }
    // console.log('result --> ', result)
    fs.writeFileSync(filePath, result, { encoding: 'utf-8' });
}
