// contracts/AlienVacation.sol
// SPDX-License-Identifier: MIT
// Inspired by Anonymice
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./UFO.sol";
import "./AlienVacationLibrary.sol";

contract AlienVacation is ERC721Enumerable {

    using AlienVacationLibrary for uint8;

    struct Trait {
        string traitName;
        string traitType;
        string pixels;
        uint256 pixelCount;
    }


    //Mappings
    mapping(uint256 => Trait[]) public traitTypes;
    mapping(string => bool) hashToMinted;
    mapping(uint256 => string) internal tokenIdToHash;

    //uint256s
    uint256 MAX_SUPPLY = 10000;
    uint256 MINTS_PER_TIER = 2000;
    uint256 SEED_NONCE = 0;

    //string arrays
    string[] LETTERS = [
        "a",
        "b",
        "c",
        "d",
        "e",
        "f",
        "g",
        "h",
        "i",
        "j",
        "k",
        "l",
        "m",
        "n",
        "o",
        "p",
        "q",
        "r",
        "s",
        "t",
        "u",
        "v",
        "w",
        "x",
        "y",
        "z"
    ];

    //uint arrays
    uint16[][6] TIERS;

    //address
    address ufoAddress;
    address _owner;

    constructor() ERC721("Alien Vacation", "AV") {
        _owner = msg.sender;

        //Declare all the rarity tiers
        //Accessories
        TIERS[0] = [100, 200, 300, 500, 700, 1000, 1000, 1300, 1900, 3000];
        //Mouth
        TIERS[1] = [100, 200, 300, 500, 700, 1100, 1100, 1300, 1700, 3000];
        //Eyes
        TIERS[2] = [25, 175, 200, 300, 500, 500, 500, 2000, 2500, 3300];
        //Headwear
        TIERS[3] = [25, 50, 100, 325, 500, 1500, 1500, 1500, 1500, 3000];
        //Body
        TIERS[4] = [20, 200, 300, 500, 3580, 5400];
        //Background
        TIERS[5] = [100, 200, 300, 500, 700, 1000, 1000, 1500, 2200, 2500];

    }

    /*
  __  __ _     _   _             ___             _   _
 |  \/  (_)_ _| |_(_)_ _  __ _  | __|  _ _ _  __| |_(_)___ _ _  ___
 | |\/| | | ' \  _| | ' \/ _` | | _| || | ' \/ _|  _| / _ \ ' \(_-<
 |_|  |_|_|_||_\__|_|_||_\__, | |_| \_,_|_||_\__|\__|_\___/_||_/__/
                         |___/
   */

    /**
     * @dev Converts a digit from 0 - 10000 into its corresponding rarity based on the given rarity tier.
     * @param _randinput The input from 0 - 10000 to use for rarity gen.
     * @param _rarityTier The tier to use.
     */
    function rarityGen(uint256 _randinput, uint8 _rarityTier)
        internal
        view
        returns (string memory)
    {
        uint16 currentLowerBound = 0;
        for (uint8 i = 0; i < TIERS[_rarityTier].length; i++) {
            uint16 thisPercentage = TIERS[_rarityTier][i];
            if (
                _randinput >= currentLowerBound &&
                _randinput < currentLowerBound + thisPercentage
            ) return i.toString();
            currentLowerBound = currentLowerBound + thisPercentage;
        }

        revert();
    }

    /**
     * @dev Generates a 9 digit hash from a tokenId, address, and random number.
     * @param _t The token id to be used within the hash.
     * @param _a The address to be used within the hash.
     * @param _c The custom nonce to be used within the hash.
     */
    function hash(
        uint256 _t,
        address _a,
        uint256 _c
    ) internal returns (string memory) {
        require(_c < 10);

        // This will generate a 7 character string.
        //The last 6 digits are random, the first is 0, due to the mouse not being burned.
        string memory currentHash = "0";

        for (uint8 i = 0; i < 6; i++) {
            SEED_NONCE++;
            uint16 _randinput = uint16(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty,
                            _t,
                            _a,
                            _c,
                            SEED_NONCE
                        )
                    )
                ) % 10000
            );

            currentHash = string(
                abi.encodePacked(currentHash, rarityGen(_randinput, i))
            );
        }

        if (hashToMinted[currentHash]) return hash(_t, _a, _c + 1);

        return currentHash;
    }

    /**
     * @dev Returns the current ufo cost of minting.
     */
    function currentUfoCost() public view returns (uint256) {
        uint256 _totalSupply = totalSupply();

        if (_totalSupply <= 2000) return 0;
        if (_totalSupply > 2000 && _totalSupply <= 4000)
            return 1000000000000000000;
        if (_totalSupply > 4000 && _totalSupply <= 6000)
            return 2000000000000000000;
        if (_totalSupply > 6000 && _totalSupply <= 8000)
            return 3000000000000000000;
        if (_totalSupply > 8000 && _totalSupply <= 10000)
            return 4000000000000000000;

        revert();
    }

    /**
     * @dev Mint internal, this is to avoid code duplication.
     */
    function mintInternal() internal {
        uint256 _totalSupply = totalSupply();
        require(_totalSupply < MAX_SUPPLY);
        require(!AlienVacationLibrary.isContract(msg.sender));

        uint256 thisTokenId = _totalSupply;

        tokenIdToHash[thisTokenId] = hash(thisTokenId, msg.sender, 0);

        hashToMinted[tokenIdToHash[thisTokenId]] = true;

        _mint(msg.sender, thisTokenId);
    }

    /**
     * @dev Mints new tokens.
     */
    function mintAlien() public {
        if (totalSupply() < MINTS_PER_TIER) return mintInternal();

        //Burn this much ufo
        UFO(ufoAddress).burnFrom(msg.sender, currentUfoCost());

        return mintInternal();
    }

    /**
     * @dev Burns and mints new.
     * @param _tokenId The token to burn.
     */
    function burnForMint(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender);

        //Burn token
        _transfer(
            msg.sender,
            0x000000000000000000000000000000000000dEaD,
            _tokenId
        );

        mintInternal();
    }

    /*
 ____     ___   ____  ___        _____  __ __  ____     __ ______  ____  ___   ____   _____
|    \   /  _] /    ||   \      |     ||  |  ||    \   /  ]      ||    |/   \ |    \ / ___/
|  D  ) /  [_ |  o  ||    \     |   __||  |  ||  _  | /  /|      | |  ||     ||  _  (   \_
|    / |    _]|     ||  D  |    |  |_  |  |  ||  |  |/  / |_|  |_| |  ||  O  ||  |  |\__  |
|    \ |   [_ |  _  ||     |    |   _] |  :  ||  |  /   \_  |  |   |  ||     ||  |  |/  \ |
|  .  \|     ||  |  ||     |    |  |   |     ||  |  \     | |  |   |  ||     ||  |  |\    |
|__|\_||_____||__|__||_____|    |__|    \__,_||__|__|\____| |__|  |____|\___/ |__|__| \___|

*/

    /**
     * @dev Helper function to reduce pixel size within contract
     */
    function letterToNumber(string memory _inputLetter)
        internal
        view
        returns (uint8)
    {
        for (uint8 i = 0; i < LETTERS.length; i++) {
            if (
                keccak256(abi.encodePacked((LETTERS[i]))) ==
                keccak256(abi.encodePacked((_inputLetter)))
            ) return (i + 1);
        }
        revert();
    }

    /**
     * @dev Hash to SVG function
     */
    function hashToSVG(string memory _hash)
        public
        view
        returns (string memory)
    {
        string memory svgString;
        bool[24][24] memory placedPixels;

        for (uint8 i = 0; i < 7; i++) {
            uint8 thisTraitIndex = AlienVacationLibrary.parseInt(
                AlienVacationLibrary.substring(_hash, i, i + 1)
            );

            for (
                uint16 j = 0;
                j < traitTypes[i][thisTraitIndex].pixelCount;
                j++
            ) {
                string memory thisPixel = AlienVacationLibrary.substring(
                    traitTypes[i][thisTraitIndex].pixels,
                    j * 4,
                    j * 4 + 4
                );

                uint8 x = letterToNumber(
                    AlienVacationLibrary.substring(thisPixel, 0, 1)
                );
                uint8 y = letterToNumber(
                    AlienVacationLibrary.substring(thisPixel, 1, 2)
                );

                if (placedPixels[x][y]) continue;

                svgString = string(
                    abi.encodePacked(
                        svgString,
                        "<rect class='c",
                        AlienVacationLibrary.substring(thisPixel, 2, 4),
                        "' x='",
                        x.toString(),
                        "' y='",
                        y.toString(),
                        "'/>"
                    )
                );

                placedPixels[x][y] = true;
            }
        }

        svgString = string(
            abi.encodePacked(
                '<svg id="alien-svg" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 24 24"> ',
                svgString,
                "<style>rect{width:1px;height:1px;} #alien-svg{shape-rendering: crispedges;} .c00{fill:#000000}.c01{fill:#323C39}.c02{fill:#847E87}.c03{fill:#A0A0A0}.c04{fill:#A49393}.c05{fill:#9BADB7}.c06{fill:#CFCFCF}.c07{fill:#3000FF}.c08{fill:#3E51FB}.c09{fill:#5266FA}.c10{fill:#43D6A7}.c11{fill:#3F3F74}.c12{fill:#5B6EE1}.c13{fill:#37946E}.c14{fill:#5FCDE4}.c15{fill:#A3FBED}.c16{fill:#CBDBFC}.c17{fill:#F142FB}.c18{fill:#FD9FCC}.c19{fill:#CF9DC1}.c20{fill:#ECB3DC}.c21{fill:#DBC7EC}.c22{fill:#014508}.c23{fill:#02660C}.c24{fill:#058F13}.c25{fill:#6ABE30}.c26{fill:#99E550}.c27{fill:#CDC304}.c28{fill:#FBF236}.c29{fill:#BE560A}.c30{fill:#DF7126}.c31{fill:#D48B55}.c32{fill:#D9A066}.c33{fill:#FB9F5C}.c34{fill:#FFD970}.c35{fill:#5F1E00}.c36{fill:#663931}.c37{fill:#8A6F30}.c38{fill:#FB2323}.c39{fill:#FF5555}.c40{fill:#AC3232}.c41{fill:#EEC39A}.c42{fill:#639BFF}.c43{fill:#94BF98}.c44{fill:#FFA500}.c45{fill:#D77BBA}.c46{fill:#D95763}.c47{fill:#8F563B}.c48{fill:#222034}</style></svg>"
            )
        );

        return svgString;
    }

    /**
     * @dev Hash to metadata function
     */
    function hashToMetadata(string memory _hash)
        public
        view
        returns (string memory)
    {
        string memory metadataString;

        for (uint8 i = 0; i < 7; i++) {
            uint8 thisTraitIndex = AlienVacationLibrary.parseInt(
                AlienVacationLibrary.substring(_hash, i, i + 1)
            );

            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    '{"trait_type":"',
                    traitTypes[i][thisTraitIndex].traitType,
                    '","value":"',
                    traitTypes[i][thisTraitIndex].traitName,
                    '"}'
                )
            );

            if (i != 6)
                metadataString = string(abi.encodePacked(metadataString, ","));
        }

        return string(abi.encodePacked("[", metadataString, "]"));
    }

    /**
     * @dev Returns the SVG and metadata for a token Id
     * @param _tokenId The tokenId to return the SVG and metadata for.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId));

        string memory tokenHash = _tokenIdToHash(_tokenId);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    AlienVacationLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "Alien Vacation #',
                                    AlienVacationLibrary.toString(_tokenId),
                                    '", "description": "Alien Vacation is a collection of 10,000 unique Aliens. All the metadata and images are generated and stored 100% on-chain. No IPFS, no API. Just the Ethereum blockchain.", "image": "data:image/svg+xml;base64,',
                                    AlienVacationLibrary.encode(
                                        bytes(hashToSVG(tokenHash))
                                    ),
                                    '","attributes":',
                                    hashToMetadata(tokenHash),
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    /**
     * @dev Returns a hash for a given tokenId
     * @param _tokenId The tokenId to return the hash for.
     */
    function _tokenIdToHash(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        string memory tokenHash = tokenIdToHash[_tokenId];
        //If this is a burned token, override the previous hash
        if (ownerOf(_tokenId) == 0x000000000000000000000000000000000000dEaD) {
            tokenHash = string(
                abi.encodePacked(
                    "1",
                    AlienVacationLibrary.substring(tokenHash, 1, 9)
                )
            );
        }

        return tokenHash;
    }

    /**
     * @dev Returns the wallet of a given wallet. Mainly for ease for frontend devs.
     * @param _wallet The wallet to get the tokens of.
     */
    function walletOfOwner(address _wallet)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_wallet);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_wallet, i);
        }
        return tokensId;
    }

    /*

  ___   __    __  ____     ___  ____       _____  __ __  ____     __ ______  ____  ___   ____   _____
 /   \ |  |__|  ||    \   /  _]|    \     |     ||  |  ||    \   /  ]      ||    |/   \ |    \ / ___/
|     ||  |  |  ||  _  | /  [_ |  D  )    |   __||  |  ||  _  | /  /|      | |  ||     ||  _  (   \_
|  O  ||  |  |  ||  |  ||    _]|    /     |  |_  |  |  ||  |  |/  / |_|  |_| |  ||  O  ||  |  |\__  |
|     ||  `  '  ||  |  ||   [_ |    \     |   _] |  :  ||  |  /   \_  |  |   |  ||     ||  |  |/  \ |
|     | \      / |  |  ||     ||  .  \    |  |   |     ||  |  \     | |  |   |  ||     ||  |  |\    |
 \___/   \_/\_/  |__|__||_____||__|\_|    |__|    \__,_||__|__|\____| |__|  |____|\___/ |__|__| \___|



    */

    /**
     * @dev Clears the traits.
     */
    function clearTraits() public onlyOwner {
        for (uint256 i = 0; i < 7; i++) {
            delete traitTypes[i];
        }
    }

    /**
     * @dev Add a trait type
     * @param _traitTypeIndex The trait type index
     * @param traits Array of traits to add
     */

    function addTraitType(uint256 _traitTypeIndex, Trait[] memory traits)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < traits.length; i++) {
            traitTypes[_traitTypeIndex].push(
                Trait(
                    traits[i].traitName,
                    traits[i].traitType,
                    traits[i].pixels,
                    traits[i].pixelCount
                )
            );
        }

        return;
    }

    /**
     * @dev Sets the ufo ERC20 address
     * @param _ufoAddress The ufo address
     */

    function setUfoAddress(address _ufoAddress) public onlyOwner {
        ufoAddress = _ufoAddress;
    }

    /**
     * @dev Transfers ownership
     * @param _newOwner The new owner
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _owner = _newOwner;
    }

    /**
     * @dev Modifier to only allow owner to call functions
     */
    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }
}
