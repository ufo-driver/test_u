#!/usr/bin/env perl

use Mojolicious::Lite;
use DBIx::Connector;

my $user_db = '';
my $pass_db = '';
my $host_db = '';
my $name_db = '';

my $data_source = "dbi:mysql:database=$name_db;mysql_client_found_rows=1;mysql_enable_utf8=1;host=$host_db";

my $DBH = DBIx::Connector->new($data_source, $user_db, $pass_db, {
	RaiseError => 1,
	AutoCommit => 1,
	mysql_enable_utf8 => 1,
});

$DBH->mode('ping');

get '/' => sub {

  my $self = shift;
  $self->render(template => 'index');
  return;

};

get '/search' => sub {

  my $self = shift;
  my $email = $self->param('email');

  my $SQL = ("
      SELECT
      sub_query.cc 
    FROM
      (
      SELECT
        log.int_id,
        log.created,
        concat( log.created, ' ', log.str ) AS cc 
      FROM
        log 
      WHERE
        log.address = (?)
        
        UNION ALL
        
      SELECT
        message.int_id,
        message.created,
        concat( message.created, ' ', message.str ) AS cc 
      FROM
        message 
      WHERE
        message.int_id IN ( SELECT log.int_id FROM log WHERE log.address = (?) ) 
      ) AS sub_query 
    ORDER BY
      int_id,
      created ASC
  ");

  my $query = $DBH->run(sub {
    my $query = $_->prepare($SQL);
    $query->execute($email,$email);
    $query;
  });

  my ($count,@row);

  if ( $query->rows ) {

      while ( my $ln = $query->fetchrow_hashref() ) {

        $count++;
        if ( $count <= 100 ) {
          push(@row,$ln->{'cc'});
        }

      }

      if ( $count > 100 ) { $self->stash(notice => 'Количество сообщений превышает 100, выведены первые 100 записей.'); }
      
      
      $self->stash(row => \@row);
      $self->render(template => 'search');
      return;

  }

  $self->stash(notice => 'Сообщения не найдены. <a href=/>Вернуться</a>');
  $self->render(template => 'search');
  return;

};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'index';
<form action="/search">
  <div>
    <label for="email">Email: </label>
    <input id="email" type="text" name="email">
    <input type="submit" value="Отправить">
  </div>
</form>

@@ search.html.ep
% layout 'default';
% title 'search result';

% if ( stash ('notice') ) {
  <font color='red'> <%== stash ('notice') %> <BR></font>
% }

% if ( stash ('row') ) {
  % foreach ( @{stash ('row')} ) {
    <%== $_ %><BR>
  % }
% }

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>

