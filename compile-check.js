const solc = require("solc");
const fs = require("fs");
const path = require("path");

function findImports(importPath) {
  const fullPath = path.join(__dirname, "node_modules", importPath);
  if (fs.existsSync(fullPath)) {
    return { contents: fs.readFileSync(fullPath, "utf8") };
  }
  return { error: "File not found: " + importPath };
}

const source = fs.readFileSync(path.join(__dirname, "contracts/MonadEscrow.sol"), "utf8");

const input = {
  language: "Solidity",
  sources: { "MonadEscrow.sol": { content: source } },
  settings: {
    outputSelection: { "*": { "*": ["abi", "evm.bytecode"] } },
    optimizer: { enabled: true, runs: 200 }
  }
};

const output = JSON.parse(solc.compile(JSON.stringify(input), { import: findImports }));

let hasError = false;
if (output.errors) {
  for (const err of output.errors) {
    if (err.severity === "error") {
      hasError = true;
      console.log("ERROR:", err.formattedMessage);
    } else {
      console.log("WARNING:", err.formattedMessage);
    }
  }
}

if (!hasError) {
  console.log("\n✅ Contract compiled successfully with no errors.");
  const contract = output.contracts["MonadEscrow.sol"]["MonadEscrow"];
  console.log("Bytecode size:", contract.evm.bytecode.object.length / 2, "bytes");
} else {
  process.exit(1);
}
