import MetadataViews from "./MetadataViews.cdc"

pub contract NFTCatalog {

  pub event EntryAdded(
    collectionName : String, 
    contractName : String, 
    contractAddress : Address, 
    nftType : Type, 
    storagePath: StoragePath, 
    publicPath: PublicPath, 
    privatePath: PrivatePath, 
    publicLinkedType : Type, 
    privateLinkedType : Type,
    displayName : String,
    description: String,
    externalURL : String
  )

  pub event ProposalEntryAdded(proposalID : UInt64, message: String, status: String, proposer : Address)
  
  pub event ProposalEntryUpdated(proposalID : UInt64, message: String, status: String, proposer : Address)
  
  pub event ProposalEntryRemoved(proposalID : UInt64)

  pub let ProposalManagerStoragePath: StoragePath

  pub let ProposalManagerPublicPath: PublicPath

  
  access(self) let catalog: {String : NFTCatalog.NFTCatalogMetadata}
  access(self) let catalogProposals : {UInt64 : NFTCatalogProposal}

  access(self) var totalProposals : UInt64

  pub resource interface NFTCatalogProposalManagerPublic {
    pub fun getCurrentProposalEntry(): String?
	}
  pub resource NFTCatalogProposalManager : NFTCatalogProposalManagerPublic {
      access(self) var currentProposalEntry: String?

      pub fun getCurrentProposalEntry(): String? {
        return self.currentProposalEntry
      }

      pub fun setCurrentProposalEntry(name: String?) {
        self.currentProposalEntry = name
      }
      
      init () {
        self.currentProposalEntry = nil
      }
  }

  pub struct NFTCollectionData {
    
    pub let storagePath : StoragePath
    pub let publicPath : PublicPath
    pub let privatePath: PrivatePath
    pub let publicLinkedType: Type
    pub let privateLinkedType: Type

    init(
      storagePath : StoragePath,
      publicPath : PublicPath,
      privatePath : PrivatePath,
      publicLinkedType : Type,
      privateLinkedType : Type
    ) {
      self.storagePath = storagePath
      self.publicPath = publicPath
      self.privatePath = privatePath
      self.publicLinkedType = publicLinkedType
      self.privateLinkedType = privateLinkedType
    }
  }


  pub struct NFTCollectionMetadata {
    
    pub let contractName : String
    pub let contractAddress : Address
    pub let nftType: Type
    pub let collectionData: NFTCollectionData
    pub let collectionDisplay: MetadataViews.NFTCollectionDisplay

    init (contractName : String, contractAddress : Address, nftType: Type, collectionData : NFTCollectionData, collectionDisplay : MetadataViews.NFTCollectionDisplay) {
      self.contractName = contractName
      self.contractAddress = contractAddress
      self.nftType = nftType
      self.collectionData = collectionData
      self.collectionDisplay = collectionDisplay
    }
  }

  pub struct NFTCatalogMetadata {
    pub let collectionName : String // Unique
    pub let collectionMetadata : NFTCollectionMetadata

    init(collectionName : String, collectionMetadata: NFTCollectionMetadata) {
      self.collectionName = collectionName
      self.collectionMetadata = collectionMetadata
    }
  }

  pub struct NFTCatalogProposal {
    pub let metadata : NFTCatalogMetadata
    pub let message : String
    pub let status : String
    pub let proposer : Address
    pub let createdTime : UFix64

    init(metadata : NFTCatalogMetadata, message : String, status : String, proposer : Address) {
      self.metadata = metadata
      self.message = message
      self.status = status
      self.proposer = proposer
      self.createdTime = getCurrentBlock().timestamp
    }
  }

  pub fun getCatalog() : {String : NFTCatalogMetadata} {
    return self.catalog
  }

  pub fun getCatalogEntry(collectionName : String) : NFTCatalogMetadata? {
    return self.catalog[collectionName]
  }

  pub fun proposeNFTMetadata(metadata : NFTCatalogMetadata, message : String, proposer : Address) : UInt64 {
    pre {
      self.catalog[metadata.collectionName] == nil : "The nft name has already been added to the catalog"
    }
    let proposerManagerCap = getAccount(proposer).getCapability<&NFTCatalogProposalManager{NFTCatalog.NFTCatalogProposalManagerPublic}>(NFTCatalog.ProposalManagerPublicPath)

    assert(proposerManagerCap.check(), message : "Proposer needs to set up a manager")

    let proposerManagerRef = proposerManagerCap.borrow()!

    assert(proposerManagerRef.getCurrentProposalEntry()! == metadata.collectionName, message: "Expected proposal entry does not match entry for the proposer")
    
    let catalogProposal = NFTCatalogProposal(metadata : metadata, message : message, status: "IN_REVIEW", proposer: proposer)
    self.totalProposals = self.totalProposals + 1
    self.catalogProposals[self.totalProposals] = catalogProposal

    emit ProposalEntryAdded(proposalID : self.totalProposals, message: catalogProposal.message, status: catalogProposal.status, proposer: catalogProposal.proposer)
    return self.totalProposals
  }

  pub fun withdrawNFTProposal(proposalID : UInt64) {
    pre {
      self.catalogProposals[proposalID] != nil : "Invalid Proposal ID"
    }
    let proposal = self.catalogProposals[proposalID]!
    let proposer = proposal.proposer

    let proposerManagerCap = getAccount(proposer).getCapability<&NFTCatalogProposalManager{NFTCatalog.NFTCatalogProposalManagerPublic}>(NFTCatalog.ProposalManagerPublicPath)

    assert(proposerManagerCap.check(), message : "Proposer needs to set up a manager")

    let proposerManagerRef = proposerManagerCap.borrow()!

    assert(proposerManagerRef.getCurrentProposalEntry()! == proposal.metadata.collectionName, message: "Expected proposal entry does not match entry for the proposer")

    self.removeCatalogProposal(proposalID : proposalID)
  }

  pub fun getCatalogProposals() : {UInt64 : NFTCatalogProposal} {
    return self.catalogProposals
  }

  pub fun getCatalogProposalEntry(proposalID : UInt64) : NFTCatalogProposal? {
    return self.catalogProposals[proposalID]
  }

  pub fun createNFTCatalogProposalManager(): @NFTCatalogProposalManager {
    return <-create NFTCatalogProposalManager()
  }

  access(account) fun addToCatalog(collectionName : String, metadata: NFTCatalogMetadata) {
    pre {
      self.catalog[collectionName] == nil : "The nft name has already been added to the catalog"
    }

    self.catalog[collectionName] = metadata

    emit EntryAdded(
      collectionName : collectionName, 
      contractName : metadata.collectionMetadata.contractName, 
      contractAddress : metadata.collectionMetadata.contractAddress, 
      nftType: metadata.collectionMetadata.nftType,
      storagePath: metadata.collectionMetadata.collectionData.storagePath, 
      publicPath: metadata.collectionMetadata.collectionData.publicPath, 
      privatePath: metadata.collectionMetadata.collectionData.privatePath, 
      publicLinkedType : metadata.collectionMetadata.collectionData.publicLinkedType, 
      privateLinkedType : metadata.collectionMetadata.collectionData.privateLinkedType,
      displayName : metadata.collectionMetadata.collectionDisplay.name,
      description: metadata.collectionMetadata.collectionDisplay.description,
      externalURL : metadata.collectionMetadata.collectionDisplay.externalURL.url
    )
  }

  access(account) fun updateCatalogProposal(proposalID: UInt64, proposalMetadata : NFTCatalogProposal) {
    self.catalogProposals[proposalID] = proposalMetadata

    emit ProposalEntryUpdated(proposalID : proposalID, message: proposalMetadata.message, status: proposalMetadata.status, proposer: proposalMetadata.proposer)
  }

  access(account) fun removeCatalogProposal(proposalID : UInt64) {
    self.catalogProposals.remove(key : proposalID)

    emit ProposalEntryRemoved(proposalID : proposalID)
  }

  init() {
    self.ProposalManagerStoragePath = /storage/nftCatalogProposalManager
    self.ProposalManagerPublicPath = /public/nftCatalogProposalManager
    
    self.totalProposals = 0
    self.catalog = {}
    self.catalogProposals = {}
  }
  
}
 