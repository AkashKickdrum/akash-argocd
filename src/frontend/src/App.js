import React, { useState } from 'react';
import logo from './logo.svg';
import './App.css';

function App() {
  const [formData, setFormData] = useState({
    currencyFrom: '',
    currencyTo: '',
    exchangeRate: '',
    sourceCurrency: '',
    targetCurrency: ''
  });

  const [postResponse, setPostResponse] = useState(null);
  const [getResponse, setGetResponse] = useState(null);
  const [totalCountResponse, setTotalCountResponse] = useState(null);

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  // Cluster backend service name is "first-service-eks-and-rds" exposed on 8080
  const react_app_url = "http://localhost:8080";

  // Function to render the POST response in a table format
  const renderPostResponseTable = () => {
    return (
      <div>
        <h2>POST Response</h2>
        <table className="response-table">
          <thead>
            <tr>
              <th>Transaction ID</th>
              <th>Source Currency</th>
              <th>Target Currency</th>
              <th>Amount</th>
              <th>Last Updated</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>{postResponse.transactionId}</td>
              <td>{postResponse.sourceCurrency}</td>
              <td>{postResponse.targetCurrency}</td>
              <td>{postResponse.amount}</td>
              <td>{postResponse.lastUpdated}</td>
            </tr>
          </tbody>
        </table>
      </div>
    );
  };

  const handleSubmitExchangeRate = async (e) => {
    e.preventDefault();

    // Get current date
    const currentDate = new Date().toISOString();

    try {
      console.log(react_app_url);
      const response = await fetch(`${react_app_url}/addExchangeRate`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          sourceCurrency: formData.currencyFrom,
          targetCurrency: formData.currencyTo,
          amount: formData.exchangeRate,
          lastUpdated: currentDate // Include current date as lastUpdated
        })
      });

      if (response.ok) {
        const responseData = await response.json();
        console.log(responseData); // Handle successful response
        setPostResponse(responseData); // Store response in state
      } else {
        console.error('Failed to submit form');
      }
    } catch (error) {
      console.error('Error:', error);
    }
  };

  const handleSubmitGetAmount = async (e) => {
    e.preventDefault();

    try {
      console.log(react_app_url);
      const response = await fetch(`${react_app_url}/getAmount?sourceCurrency=${formData.sourceCurrency}&targetCurrency=${formData.targetCurrency}`);
      
      if (response.ok) {
        const responseData = await response.json();
        console.log(responseData); // Handle successful response
        setGetResponse(responseData); // Store response in state
      } else {
        console.error('Failed to get amount');
      }
    } catch (error) {
      console.error('Error:', error);
    }
  };

  const handleGetTotalCount = async () => {
    try {
      const response = await fetch(`${react_app_url}/getTotalCount`);
  
      if (response.ok) {
        const responseData = await response.json();
        console.log(responseData); // Handle successful response
        setTotalCountResponse(responseData); // Store response in state
      } else {
        console.error('Failed to get total count');
      }
    } catch (error) {
      console.error('Error:', error);
    }
  };
  
  return (
    <div className="App">
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
        <p>
          Edit <code>src/App.js</code> and save to reload.
        </p>
        <form id="exchangeRateForm" onSubmit={handleSubmitExchangeRate}>
          <input type="text" name="currencyFrom" placeholder="Currency From" value={formData.currencyFrom} onChange={handleChange} />
          <input type="text" name="currencyTo" placeholder="Currency To" value={formData.currencyTo} onChange={handleChange} />
          <input type="text" name="exchangeRate" placeholder="Exchange Rate" value={formData.exchangeRate} onChange={handleChange} />
          <button type="submit">Submit</button>
        </form>
        <form id="getAmountForm" onSubmit={handleSubmitGetAmount}>
          <input type="text" name="sourceCurrency" placeholder="Source Currency" value={formData.sourceCurrency} onChange={handleChange} />
          <input type="text" name="targetCurrency" placeholder="Target Currency" value={formData.targetCurrency} onChange={handleChange} />
          <button type="submit">Get Exchange Rate</button>
        </form>

        {/* Display POST response */}
        {postResponse && renderPostResponseTable()}

        {/* Display GET response */}
        {getResponse && (
          <div>
            <h2>GET Response</h2>
            <pre>{JSON.stringify(getResponse, null, 2)}</pre>
          </div>
        )}

        {/* Display Total Count response */}
        {totalCountResponse && (
          <div>
            <h2>Total Count Response</h2>
            <pre>{JSON.stringify(totalCountResponse, null, 2)}</pre>
          </div>
        )}

        {/* Button to get Total Count */}
        <button onClick={handleGetTotalCount}>GetTotalRecordCount</button>
        
        <a
          className="App-link"
          href="https://reactjs.org"
          target="_blank"
          rel="noopener noreferrer"
        >
          Learn React
        </a>
      </header>
    </div>
  );
}

export default App;
