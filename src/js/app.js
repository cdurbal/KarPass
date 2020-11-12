App = {
  web3Provider: null,
  contracts: {},

  init: async function() {
    // Load pets.
    /*$.getJSON('../pets.json', function(data) {
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
    });*/

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

      App.initPassports();
      
      return App.displaySmartContract();
    });

    return App.bindEvents();
  },

  initPassports: function() {
    var passInstance;

    web3.eth.getAccounts(function(error, accounts) {
        if (error) {
            console.log(error);
        }

        var account = accounts[0];

        App.contracts.KarPassport.deployed().then(function(instance) {
          passInstance = instance;

          // Load passports.
          passInstance.passportIdentifiants({from: account}).then(function (ids) {
            console.log("Passports : " + ids);
          
            var passportsRow = $('#passportsRow');
            var passTemplate = $('#passTemplate');

            for (i = 0; i < ids.length; i ++) {
              passInstance.passport(ids[i] ,{from: account}).then(
                function (passport) {

                  var name = passport[0];
                  var id = passport[1];
                  var brand = passport[2];
                  var modele = passport[3];
                  var year = passport[4];
                  var numberPlate = passport[5];
                  var km = passport[6];
                  var technicalControlExpirationDate = passport[7];
                  var insuranceExpirationDate = passport[8];

                  console.log("Passport : name " + name + ", id " + id + ", brand " + brand 
                  + ", modele " + modele + ", year " + year 
                  + ", numberPlate " + numberPlate + ", km " + km  
                  + ", technicalControlExpirationDate " + technicalControlExpirationDate 
                  +  ", insuranceExpirationDate " + insuranceExpirationDate);
                
                  passTemplate.find('.panel-title').text(name);
                  passTemplate.find('.pass-name').text(name);
                  passTemplate.find('img').attr('src', "https://pngimg.com/uploads/peugeot/peugeot_PNG56.png");
                  passTemplate.find('.pass-vin').text(id);
                  passTemplate.find('.pass-km').text(km);
                  passTemplate.find('.pass-release').text(year);
                  passTemplate.find('.btn-delete').attr('data-id', ids[0]);

                  passTemplate.find('.col-sm-6').attr('data-id', ids[0]);
                  passTemplate.find('.col-sm-6').attr('id', ids[0]);

                  passportsRow.append(passTemplate.html());
                });
            }
          
          }).catch(function(err) {
            console.log(err.message);
          });

          passInstance.balanceOf(account, {from: account}).then(function (balance) {
            $('#balance').text(balance.toNumber());
            console.log("balance on smart contract: " + balance.toNumber());
          });

        }).catch(function(err) {
            console.log(err.message);
        });

    });
  },
  
  
  bindEvents: function() {
    $(document).on('click', '.btn-approve', App.handleApprove);    
    $(document).on('click', '.btn-create', App.handleCreatePassport);
    $(document).on('click', '.btn-delete', App.handleDelete);
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
  


  displaySmartContract: function() {
        App.displayAccount();
        App.displayPassportAccount();
  },

  displayAccount: function() {

    var tokenInstance;

    web3.eth.getAccounts(function(error, accounts) {
        if (error) {
            console.log(error);
        }

        var account = accounts[0];

        App.contracts.KarToken.deployed().then(function(instance) {
          tokenInstance = instance;
          $('#address').text(account);
          tokenInstance.balanceOf(account, {from: account}).then(function (bal) {
            $('#account').text(bal.toNumber());
            console.log("Account :" + bal.toNumber());
          });
        }).catch(function(err) {
            console.log(err.message);
        });


    });
  },


  displayPassportAccount: function() {

    var passInstance;

    web3.eth.getAccounts(function(error, accounts) {
        if (error) {
            console.log(error);
        }

        var account = accounts[0];

        App.contracts.KarPassport.deployed().then(function(instance) {
          passInstance = instance;
          passInstance.totalPassport(account, {from: account}).then(function (total) {
            $('#total').text(total.toNumber());
            console.log("Total pasport : " + total.toNumber());
          });

          passInstance.balanceOf(account, {from: account}).then(function (balance) {
            $('#balance').text(balance.toNumber());
            console.log("balance on smart contract: " + balance.toNumber());
          });

          passInstance.passportIdentifiants({from: account}).then(function (ids) {
            console.log("list passport: " + ids);
          });

          

        }).catch(function(err) {
            console.log(err.message);
        });

    });
  },

  handleApprove: function(event) {
    event.preventDefault();

    var passInstance;
    var tokenInstance;

    web3.eth.getAccounts(function(error, accounts) {
        if (error) {
            console.log(error);
        }

        var account = accounts[0];

        App.contracts.KarToken.deployed().then(function(instance) {
          tokenInstance = instance;
            App.contracts.KarPassport.deployed().then(function(instanceP) {
              passInstance = instanceP;
              
              var tokenToTransfer = document.getElementById("token").value;
              
              //$('.panel-pet').eq(15).find('button').text('Success KarPassport deployed').attr('disabled', true);
              tokenInstance.approve(passInstance.address, tokenToTransfer, {from: account}).then(function() {
                console.log("approve "  + tokenToTransfer  + " token from " + account);
                passInstance.transferAllowedToken({from: account}).then(function() {
                  console.log("transfer allowed tokens to katPassport from " + account);
                  //mettre à jour les info du contrat
                  App.displaySmartContract();
                }).catch(function(err) {
                  console.log(err.message);
                });
              }).catch(function(err) {
                console.log(err.message);
              });

            }).catch(function(err) {
              console.log(err.message);
            });
            
        }).catch(function(err) {
            console.log(err.message);
        });
    });
  },

  handleCreatePassport: function(event) {
    event.preventDefault();

    var passInstance;
    var tokenInstance;

    web3.eth.getAccounts(function(error, accounts) {
        if (error) {
            console.log(error);
        }

        var account = accounts[0];

        App.contracts.KarToken.deployed().then(function(instance) {
          tokenInstance = instance;
            App.contracts.KarPassport.deployed().then(function(instanceP) {
              passInstance = instanceP;
              
              var name = document.getElementById("name").value;
              var VIN = document.getElementById("VIN").value;
              var brand = document.getElementById("brand").value;
              var modele = document.getElementById("modele").value;
              var realeaseDate = new Date(document.getElementById("releaseDate").value).getFullYear();

              console.log("Passport : name "  + name  + ", VIN " + VIN + ", brand " + brand + ", modele " + modele + ", realeaseDate " + realeaseDate);
              passInstance.createPassport(name, VIN, brand, modele, realeaseDate, "AAAAAA", {from: account}).then(function(id) {
                console.log("create Passport " + id + " for " + account);

                passInstance.totalPassport(account, {from: account}).then(function (total) {
                  $('#total').text(total.toNumber());
                  console.log("Total pasport : " + total.toNumber());
                });
                var passportsRow = $('#passportsRow');
                var passTemplate = $('#passTemplate');

                passTemplate.find('.panel-title').text(name);
                passTemplate.find('.pass-name').text(name);
                passTemplate.find('img').attr('src', "https://pngimg.com/uploads/peugeot/peugeot_PNG56.png");
                passTemplate.find('.pass-vin').text(VIN);
                passTemplate.find('.pass-km').text(0);
                passTemplate.find('.pass-release').text(realeaseDate);
                passTemplate.find('.col-sm-6').attr('data-id', id);
                passTemplate.find('.col-sm-6').attr('id', id);

                passTemplate.find('.btn-delete').attr('data-id', id);

                passportsRow.append(passTemplate.html());

                /*
                var parent = document.getElementById('passportsRow');
                parent.append(passTemplate.html());*/

              }).catch(function(err) {
                console.log(err.message);
              });

            }).catch(function(err) {
              console.log(err.message);
            });
            
        }).catch(function(err) {
            console.log(err.message);
        });
    });
  },

  handleDelete: function(event) {
    event.preventDefault();

    var karId = parseInt($(event.target).data('id'));

    console.log("Event : " + event);
    console.log("Id to delete : " + karId);

    event.preventDefault();

    var passInstance;

    web3.eth.getAccounts(function(error, accounts) {
        if (error) {
            console.log(error);
        }

        var account = accounts[0];

        App.contracts.KarPassport.deployed().then(function(instanceP) {
          passInstance = instanceP;

          passInstance.deletePassport(karId, {from: account}).then(function(id) {
            console.log("delete Passport " + karId + " of " + account);
            var element = document.getElementById(karId);
            element.parentNode.removeChild(element);

          }).catch(function(err) {
            console.log(err.message);
          });

        }).catch(function(err) {
          console.log(err.message);
        });
    });
  },
  
  handleAdopt: function(event) {
    event.preventDefault();

    var petId = parseInt($(event.target).data('id')).toString();

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
