public class CreateInvoiceController {
    public List<InvoiceField> invoiceDetails { get; set; }
    public String jsonOutput { get; set; }

    public static final String ORIGIN_RECORD_PARAM = 'origin_record';
    public static final String ACCOUNT_PARAM = 'account';
    public static final String INVOICE_DATE_PARAM = 'invoice_date';
    public static final String INVOICE_DUE_DATE_PARAM = 'invoice_due_date';
    public static final String CHILD_RELATIONSHIP_NAME_PARAM = 'child_relationship_name';
    public static final String LINE_ITEM_DESCRIPTION_PARAM = 'line_item_description';
    public static final String LINE_ITEM_QUANTITY_PARAM = 'line_item_quantity';
    public static final String LINE_ITEM_UNIT_PRICE_PARAM = 'line_item_unit_price';
    
    // Map to store invoice field values
    private Map<String, String> invoiceFieldMap;

    public CreateInvoiceController(ApexPages.StandardController controller) {
        invoiceDetails = new List<InvoiceField>();
        invoiceFieldMap = new Map<String, String>();

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
        Map<String, String> parameters = ApexPages.currentPage().getParameters();
        String paramValue = (parameters != null) ? parameters.get(paramName) : null;

        if (String.isBlank(paramValue)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Required parameter ' + paramName + ' is missing.'));
        }
        
        invoiceDetails.add(new InvoiceField(paramName, String.isBlank(paramValue) ? '' : paramValue));
        invoiceFieldMap.put(paramName, String.isBlank(paramValue) ? '' : paramValue);
    }

    public PageReference generateJSON() {
        String originRecordId = getInvoiceFieldValue(ORIGIN_RECORD_PARAM);
        
        if (String.isNotBlank(originRecordId)) {
            // Fetch lineitems fields
            Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('OpportunityLineItem').getDescribe().fields.getMap();
            List<String> fieldsToSelect = new List<String>();

            // Gather fields to select
            gatherFieldsToSelect(fieldMap, fieldsToSelect);

            if (!fieldsToSelect.isEmpty()) {
                jsonOutput = generateInvoiceJSON(originRecordId, fieldsToSelect);
            } else {
                jsonOutput = 'Error: No valid fields found in OpportunityLineItem.';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, jsonOutput));
            }
        } else {
            jsonOutput = 'Error: No valid origin record ID provided.';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, jsonOutput));
        }
        return null; 
    }

    private void gatherFieldsToSelect(Map<String, Schema.SObjectField> fieldMap, List<String> fieldsToSelect) {
        String itemDescription = getInvoiceFieldValue(LINE_ITEM_DESCRIPTION_PARAM);
        String itemQuantity = getInvoiceFieldValue(LINE_ITEM_QUANTITY_PARAM);
        String itemUnitPrice = getInvoiceFieldValue(LINE_ITEM_UNIT_PRICE_PARAM);

        // check is it a valid line item field api name
        if (fieldMap.containsKey(itemDescription)) {
            fieldsToSelect.add(itemDescription);
        }
        if (fieldMap.containsKey(itemQuantity)) {
            fieldsToSelect.add(itemQuantity);
        }
        if (fieldMap.containsKey(itemUnitPrice)) {
            fieldsToSelect.add(itemUnitPrice);
        }
    }

    private String generateInvoiceJSON(String originRecordId, List<String> fieldsToSelect) {
        String fieldList = String.join(fieldsToSelect, ', ');
        String query = 'SELECT ' + fieldList + ' FROM OpportunityLineItem WHERE OpportunityId = :originRecordId';
        List<OpportunityLineItem> lineItems = Database.query(query);

        if (lineItems != null && !lineItems.isEmpty()) {
            // Creating JSON generator
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject(); 
            gen.writeStringField('Type', 'ACCREC'); 
            gen.writeFieldName('Contact');
            gen.writeStartObject();
            gen.writeStringField('ContactID', '0000000'); 
            gen.writeEndObject();
            String invoiceDate = getInvoiceFieldValue(INVOICE_DATE_PARAM);
            String dueDate = getInvoiceFieldValue(INVOICE_DUE_DATE_PARAM);
            
            Date formattedInvoiceDate = convertDateFormat(invoiceDate);
            Date formattedDueDate = convertDateFormat(dueDate);
            
            if (formattedInvoiceDate != null) {
                gen.writeDateField('Date', formattedInvoiceDate);
            } 
            if (formattedDueDate != null) {
                gen.writeDateField('DueDate', formattedDueDate);
            }

            //LineItems field 
            gen.writeFieldName('LineItems');
            gen.writeStartArray();
            for (OpportunityLineItem item : lineItems) {
                gen.writeStartObject();
                gen.writeStringField('Description', item.Description);
                gen.writeStringField('Quantity', String.valueOf(item.Quantity));
                gen.writeStringField('UnitAmount', String.valueOf(item.UnitPrice));
                gen.writeEndObject();
            }
            gen.writeEndArray();
            gen.writeEndObject(); 

            // JSON string
            return gen.getAsString();
        } else {
            return 'Error: At least one Line Item is required.';
        }
    }

    private String getInvoiceFieldValue(String paramName) {
        return invoiceFieldMap.get(paramName); 
    }

    // Utility method to format date in YYYY-MM-DD
    public Date convertDateFormat(String inputDate) {
        if (String.isBlank(inputDate)) {
            return null; 
        }
        try {
            List<String> parts = inputDate.split('/');
            if (parts.size() == 3) {
                return Date.newInstance(
                    Integer.valueOf(parts[2]), // Year
                    Integer.valueOf(parts[1]), // Month
                    Integer.valueOf(parts[0])  // Day
                );
            } else {
                throw new IllegalArgumentException('Invalid date format: ' + inputDate);
            }
        } catch (Exception e) {
            System.debug('Error converting date: ' + e.getMessage());
            throw new IllegalArgumentException('Invalid date format provided: ' + inputDate);
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