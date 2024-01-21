type ModelData = {
    id: string;
    type: string;
    attributes: {
        [key: string]: string | null;
        name: string;
        description: string | null;
        query: string;
        query_type: string;
        created_at: string;
        updated_at: string;
    };
};


type TableDataType = {
	columns: Array<string>;
	data: Array<{}>;
};


export function ConvertToTableData(apiData: Array<ModelData>, columns: Array<string>, customColumnNames? : Array<string>) : TableDataType {
    let data = apiData.map(item => {
        let rowData: { [key: string]: string | null } = {};
        columns.forEach(column => {
            rowData[column] = item.attributes[column] || null;
        });
        return rowData;
    });

    return {
        columns: customColumnNames ? customColumnNames : columns,
        data: data
    };
}