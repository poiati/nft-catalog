## Cadence generation
# Cadence Generation

Using the NFT Catalog, you can generate common scripts and transactions to be run against the Flow Blockchain to support your application.

## How-to generate scripts and transactions

### From JavaScript
#### Installation

```
npm install @onflow/fcl
npm install flow-catalog
```

or

```
yarn add @onflow/fcl
yarn add flow-catalog
```

#### Usage
*1. Retrieve a list of transactions available for code generation:*
NOTE: In order to properly bootstrap the method, you will need to run and `await` on the `getAddressMaps()` method, passing it into all of the methods as shown below.

```
import { getAddressMaps, scripts } from "flow-catalog";
import * as fcl from "@onflow/fcl"

const main = async () => {
    const addressMap = await getAddressMaps();
    console.log(await scripts.getSupportedGeneratedTransactions(addressMap));
};

main();
```

*2. Provide a Catalog collection identifier to generate code*
```
const getTemplatedTransactionCode = async function() {
  const catalogAddressMap = await getAddressMaps()
  const result = await cadence.scripts.genTx({

    /*
        'CollectionInitialization' is one of the available transactions from step 1.
        'Flunks' is the collection identifier in this case
        'Flow' is a fungible token identifier (if applicable to the transaction being used)
    */
    
    args: ['CollectionInitialization', 'Flunks', 'flow'],
    addressMap: catalogAddressMap
  })
  return result
}
```

*3. Use the generated code in a transaction*
```
const txId = await fcl.mutate({
  cadence: await getTemplatedTransactionCode()[0],
  limit: 9999,
  args: (arg: any, t: any) => []
});
const transaction = await fcl.tx(txId).onceSealed()
return transaction
```

### From non-javascript environments

Cadence scripts and transactions can be generated directly on-chain via scripts. You will need to be able to run cadence scripts to continue.

*1. Retrieve a list of transactions available for code generation*

Run the following script to retrieve available code generation methods: https://github.com/dapperlabs/nft-catalog/blob/main/cadence/scripts/get_supported_generated_transactions.cdc

*2. Provide a catalog collection identifier to generate code*

You may use the following script to generate code: https://github.com/dapperlabs/nft-catalog/blob/main/cadence/scripts/gen_tx.cdc

For example, from the CLI this may be run like the following:
`flow -n mainnet scripts execute ./get_tx.cdc CollectionInitialization Flunks flow`

In the above example, `CollectionInitialization` is one of the supported transactions returned from step 1, `Flunks` is the name of an entry on the catalog (https://www.flow-nft-catalog.com/catalog/mainnet/Flunks), and `flow` is a fungible token identifier.
