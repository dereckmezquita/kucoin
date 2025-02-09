// async.js
function getData() {
    return new Promise((resolve, reject) => {
        console.log("Simulating API call, waiting 2 seconds...");
        setTimeout(() => {
            // After 2 seconds, resolve with some data
            resolve("Data received");
        }, 2000);
    });
}

console.log("Before API call");

getData()
  .then(data => {
      console.log("Inside then: " + data);
  })
  .catch(error => {
      console.error("Error fetching data: ", error);
  });

console.log("After API call");

async function main() {
    try {
        const data = await getData();
        console.log("Inside async function: " + data);
    } catch (error) {
        console.error("Error fetching data: ", error);
    }
}

main().then(() => {
    console.log("Main function completed");
});