App = {
  web3Provider: null,
  contracts: {},

  init: async function() {
    // Load pets.
    $.getJSON('../pets.json', function(data) {
      var petsRow = $('#petsRow');
      var petTemplate = $('#petTemplate');

      for (i = 0; i < data.length; i ++) {
        petTemplate.find('.panel-title').text(data[i].name);
        petTemplate.find('img').attr('src', data[i].picture);
        petTemplate.find('.pet-breed').text(data[i].breed);
        petTemplate.find('.pet-age').text(data[i].age);
        petTemplate.find('.pet-location').text(data[i].location);
        petTemplate.find('.btn-adopt').attr('data-id', data[i].id);

        petsRow.append(petTemplate.html());
      }
    });

    return await App.initWeb3();
  },

  initWeb3: async function() {
    // Modern dapp browsers...
    if (window.ethereum) {
      App.web3Provider = window.ethereum;
      try {
        // Request account access
        await window.ethereum.enable();
      } catch (error) {
        // User denied account access...
        console.error("User denied account access")
      }
    }
    // Legacy dapp browsers...
    else if (window.web3) {
      App.web3Provider = window.web3.currentProvider;
    }
    // If no injected web3 instance is detected, fall back to Ganache
    else {
      App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
    }
    web3 = new Web3(App.web3Provider);

    return App.initContract();
  },

  
  
  initContract: function() {

    $.getJSON('KarToken.json', function(data) {
      // Get the necessary contract artifact file and instantiate it with truffle-contract
      var KarArtifact = data;
      App.contracts.KarToken = TruffleContract(KarArtifact);
  
      // Set the provider for our contract
      App.contracts.KarToken.setProvider(App.web3Provider);

      return true;
    });

    $.getJSON('KarPassport.json', function(data) {
    // Get the necessary contract artifact file and instantiate it with truffle-contract
    var KarArtifact = data;
    App.contracts.KarPassport = TruffleContract(KarArtifact);

    // Set the provider for our contract
    App.contracts.KarPassport.setProvider(App.web3Provider);

    // Use our contract to retrieve and mark the adopted pets
    return App.markAdopted();
    });

    return App.bindEvents();
  },

  
  
  bindEvents: function() {
    $(document).on('click', '.btn-adopt', App.handleAdopt);
    $(document).on('click', '.btn-create', App.handleCreate);    
  },

  
  
  
  markAdopted: function(adopters, account) {
    var karInstance;

    App.contracts.KarPassport.deployed().then(function(instance) {
        karInstance = instance;

        return karInstance.getAdopters.call();
    }).then(function(adopters) {
        for (i = 0; i < adopters.length; i++) {
            if (adopters[i] !== '0x0000000000000000000000000000000000000000') {
              $('.panel-pet').eq(i).find('button').text('Success').attr('disabled', true);
            }
        }
    }).catch(function(err) {
        console.log(err.message);
    });
  },

  handleCreate: function(event) {
    event.preventDefault();
    //$('.panel-pet').eq(15).find('button').text('Success NO').attr('disabled', true);
    //$('.panel-create').eq(1).find('button').text('Success NO').attr('disabled', true);

    var passInstance;
    var tokenInstance;

    web3.eth.getAccounts(function(error, accounts) {
        if (error) {
            console.log(error);
        }

        var account = accounts[0];

        App.contracts.KarToken.deployed().then(function(instance) {
          tokenInstance = instance;
            $('.panel-pet').eq(15).find('button').text('Success karToken deployed').attr('disabled', true);

            App.contracts.KarPassport.deployed().then(function(instanceP) {
              passInstance = instanceP;
              $('.panel-pet').eq(15).find('button').text('Success KarPassport deployed').attr('disabled', true);
              tokenInstance.approve(passInstance.address, 100, {from: account});
              $('.panel-pet').eq(15).find('button').text('Success token delegate').attr('disabled', true);
              var ret = passInstance.transferAllowedToken({from: account});
              $('.panel-pet').eq(15).find('button').text('Success token transfer' + ret).attr('disabled', true);
              
              return 0;

            }).catch(function(err) {
              console.log(err.message);
            });

            // Execute adopt as a transaction by sending account
            /*return KarToken.approve("name",
              "id",
              "brand",
              "modele",
              2020,
              "numberPlate", {from: account});*/
              $('.panel-pet').eq(15).find('button').text('Success create').attr('disabled', false);
        }).catch(function(err) {
            console.log(err.message);
        });
    });
  },
  
  handleAdopt: function(event) {
    event.preventDefault();

    var petId = parseInt($(event.target).data('id'));

    var karInstance;

    web3.eth.getAccounts(function(error, accounts) {
        if (error) {
            console.log(error);
        }

        var account = accounts[0];

        App.contracts.KarPassport.deployed().then(function(instance) {
            karInstance = instance;

            // Execute adopt as a transaction by sending account
            return karInstance.adopt(petId, {from: account});
        }).then(function(result) {
            return App.markAdopted();
        }).catch(function(err) {
            console.log(err.message);
        });
    });
  }

};

$(function() {
  $(window).load(function() {
    App.init();
  });
});
