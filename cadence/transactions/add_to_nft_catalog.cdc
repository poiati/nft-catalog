import MetadataViews from "../contracts/MetadataViews.cdc"
import NFTCatalog from "../contracts/NFTCatalog.cdc"
import NFTCatalogAdmin from "../contracts/NFTCatalogAdmin.cdc"

transaction(
  collectionName : String,
  contractName: String,
  contractAddress: Address,
  nftTypeIdentifer: String,
  addressWithNFT: Address,
  nftID: UInt64,
  publicPathIdentifier: String
) {
  let adminProxyResource : &NFTCatalogAdmin.AdminProxy

  prepare(acct: AuthAccount) {
    self.adminProxyResource = acct.borrow<&NFTCatalogAdmin.AdminProxy>(from : NFTCatalogAdmin.AdminProxyStoragePath)!
  }

  execute {
    let nftAccount = getAccount(addressWithNFT)
    let pubPath = PublicPath(identifier: publicPathIdentifier)!
    let collectionRef = nftAccount.getCapability<&AnyResource{MetadataViews.ResolverCollection}>(pubPath).borrow() ?? panic("Invalid NFT data")
    let nftResolver = collectionRef.borrowViewResolver(id: nftID)
    
    let metadataCollectionData = nftResolver.resolveView(Type<MetadataViews.NFTCollectionData>())! as! MetadataViews.NFTCollectionData
    
    let collectionData = NFTCatalog.NFTCollectionData(
      storagePath: metadataCollectionData.storagePath,
      publicPath: metadataCollectionData.publicPath,
      privatePath: metadataCollectionData.providerPath,
      publicLinkedType : metadataCollectionData.publicLinkedType,
      privateLinkedType : metadataCollectionData.providerLinkedType
    )

    let collectionDisplay = nftResolver.resolveView(Type<MetadataViews.NFTCollectionDisplay>())! as! MetadataViews.NFTCollectionDisplay

    let collectionMetadata = NFTCatalog.NFTCollectionMetadata(
      contractName: contractName,
      contractAddress: contractAddress,
      nftType: CompositeType(nftTypeIdentifer)!,
      collectionData: collectionData,
      collectionDisplay : collectionDisplay
    )

    let catalogData = NFTCatalog.NFTCatalogMetadata(collectionName: collectionName, collectionMetadata: collectionMetadata)
    
    self.adminProxyResource.getCapability()!.borrow()!.addCatalogEntry(collectionName : collectionName, metadata : catalogData)
  }
}