import TransactionGeneration from "../contracts/TransactionGeneration.cdc"

pub fun main(tx: String, collectionIdentifier: String, vaultIdentifier: String) : String {
    return TransactionGeneration.getTx(tx: tx, params: {
        "collectionIdentifier": collectionIdentifier,
        "vaultIdentifier": vaultIdentifier
    })!
}
