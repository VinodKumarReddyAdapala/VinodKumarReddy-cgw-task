public class CreateInvoiceController {
    public List<InvoiceField> invoiceDetails { get; set; }
    
    public static final String ORIGIN_RECORD_PARAM = 'origin_record';
    public static final String ACCOUNT_PARAM = 'account';
    public static final String INVOICE_DATE_PARAM = 'invoice_date';
    public static final String INVOICE_DUE_DATE_PARAM = 'invoice_due_date';
    public static final String CHILD_RELATIONSHIP_NAME_PARAM = 'child_relationship_name';
    public static final String LINE_ITEM_DESCRIPTION_PARAM = 'line_item_description';
    public static final String LINE_ITEM_QUANTITY_PARAM = 'line_item_quantity';
    public static final String LINE_ITEM_UNIT_PRICE_PARAM = 'line_item_unit_price';

    public CreateInvoiceController(ApexPages.StandardController controller) {
        invoiceDetails = new List<InvoiceField>();
        addInvoiceField(ORIGIN_RECORD_PARAM);
        addInvoiceField(ACCOUNT_PARAM);
        addInvoiceField(INVOICE_DATE_PARAM);
        addInvoiceField(INVOICE_DUE_DATE_PARAM);
        addInvoiceField(CHILD_RELATIONSHIP_NAME_PARAM);
        addInvoiceField(LINE_ITEM_DESCRIPTION_PARAM);
        addInvoiceField(LINE_ITEM_QUANTITY_PARAM);
        addInvoiceField(LINE_ITEM_UNIT_PRICE_PARAM);
    }

    private void addInvoiceField(String paramName) {
        String paramValue = ApexPages.currentPage().getParameters().get(paramName);
        if (!String.isBlank(paramValue)) {
            invoiceDetails.add(new InvoiceField(paramName, paramValue));
        } else {
            invoiceDetails.add(new InvoiceField(paramName, 'N/A'));
        }
    }

    public class InvoiceField {
        public String fieldName { get; set; }
        public String fieldValue { get; set; }

        public InvoiceField(String fieldName, String fieldValue) {
            this.fieldName = fieldName;
            this.fieldValue = fieldValue;
        }
    }
}