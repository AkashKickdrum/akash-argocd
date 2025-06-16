# Exchange Rate Service

This Java application provides an Exchange Rate Service that allows users to perform various operations related to currency exchange rates.

## Endpoints

### 1. Get Amount
- **HTTP Method:** GET
- **Endpoint:** /getAmount
- **Parameters:**
  - sourceCurrency (String): The source currency code.
  - targetCurrency (String): The target currency code.
- **Description:** Retrieves the exchange rate from the source currency to the target currency.

### 2. Get Total Count
- **HTTP Method:** GET
- **Endpoint:** /getTotalCount
- **Description:** Retrieves the total count of exchange rates available in the service.

### 3. Add Exchange Rate
- **HTTP Method:** POST
- **Endpoint:** /addExchangeRate
- **Request Body:** ExchangeRate object
- **Description:** Adds a new exchange rate to the service.

### 4. Get Health
- **HTTP Method:** GET
- **Endpoint:** /
- **Description:** Checks the health of the service. Returns "up" if the service is running.

## Running the Application

To run the application, make sure you have Java installed on your system. Then, you can compile and run the application using the following steps:

1. Clone the repository:
   ```bash
   git clone <repository-url>

2. Navigate to the project directory:
   ```bash
   cd <project-directory>

   
3. Build the gradle application
   ```bash
   
# kdu-backend-app-1
