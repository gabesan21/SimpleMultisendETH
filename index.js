
// Your contract address
const contractMumbai = "0xEB74f2097Dd6713B49Cc92f4cA2cB39Bc100843c";
const contractPolygon = "0x12a57d1aCA1dc123CEcaaE2E67f0a69f6aCDde7b";
const contractEthereum = "0x9f78f4A2c5327896079E9Abb4DE978d8966f8E3B";

// Get references to the input elements
const vezes = document.getElementById("vezes");
const tokens = document.getElementById("tokens");
const resultado = document.getElementById("resultado");
const carteira = document.getElementById("carteira");
const botaoEnviar = document.getElementById("botao_enviar");


if (typeof window.ethereum !== 'undefined' && window.ethereum.isMetaMask) {
  window.ethereum.request({ method: 'eth_chainId' }).then(chainId => {
    console.log('Connected to chain:', chainId);
  }).catch(error => {
    console.log('Failed to get chain ID:', error);
    botaoEnviar.textContent = 'Conectar';
  });
} else {
  alert("MetaMask não está instalada. Instale a MetaMask para continuar.");
  botaoEnviar.textContent = 'Conectar';
}

async function enviar() {
  const provider = new ethers.providers.Web3Provider(window.ethereum);
  await provider.send("eth_requestAccounts", []);
  const signer = provider.getSigner();
  let contractAddress = "";

  const network = await provider.getNetwork();
  const chainId = network.chainId;

  if (chainId == 80001) {
    contractAddress = contractMumbai;
  } else if (chainId == 137) {
    contractAddress = contractPolygon;
  }else if (chainId == 1) {
    contractAddress = contractEthereum;
  }

  if (contractAddress == "") {
    alert("Conecte a Mumbai Testnet, Polygon Mainnet ou Ethereum Mainnet para usar o Dapp.");
    return;
  }

  const multiSendContract = new ethers.Contract(
    contractAddress,
    abiSender,
    signer
  );

  let wallets = [];
  let values = [];

  for (let i = 0; i < Number(vezes.value); i++) {
    wallets.push(carteira.value);
    values.push(Number(ethers.utils.parseEther(tokens.value)));
  }

  document.getElementById("wallets").innerHTML = JSON.stringify(wallets);
  document.getElementById("values").innerHTML = JSON.stringify(values);

  // Estimate gas for the transaction
  const estimate = await multiSendContract.multisendEther(wallets, values, { value: ethers.utils.parseEther(resultado.value) }).estimateGas();

  // Add a buffer to the estimated gas
  const gasLimit = estimate.mul(1.2); // Add a 20% buffer

  // Send the transaction with the estimated gas limit
  const tx = await multiSendContract.multisendEther(wallets, values, { value: ethers.utils.parseEther(resultado.value), gasLimit });
  console.log("Transaction hash:", tx.hash);
}


function calcular() {
  const value = Number(vezes.value);
  const tokensQtd = Number(tokens.value);
  resultado.value = (value * tokensQtd).toFixed(18);
}

// Attach an event listener to input1
vezes.addEventListener("input", calcular);

// Attach an event listener to input1
tokens.addEventListener("input", calcular);

// Attach an event listener to the input field
tokens.addEventListener("input", () => {
  // Use a regular expression to test the input value
  const regex = /^\d*\.?\d*$/; // Accepts positive and negative float numbers
  if (!regex.test(tokens.value)) {
    // If the input value is not a float number, remove the last entered character
    tokens.value = tokens.value.substring(0, tokens.value.length - 1);
  }
});
