package captiveportal::DynamicRouting::AuthModule::SAML;

=head1 NAME

captiveportal::DynamicRouting::AuthModule::SAML

=head1 DESCRIPTION

SAML authentication

=cut

use Moose;
extends 'captiveportal::DynamicRouting::AuthModule';
with 'captiveportal::DynamicRouting::Routed';

use pf::util;

has '+source' => (isa => 'pf::Authentication::Source::SAMLSource');

has '+route_map' => (default => sub {
    tie my %map, 'Tie::IxHash', (
        '/saml/redirect' => \&redirect,
        '/saml/assertion' => \&assertion,
        # fallback to the index
        '/(.*)' => \&index,
    );
    return \%map;
});

sub execute_child {
    my ($self) = @_;
    $self->index();
}

sub index {
    my ($self) = @_;
    $self->render("saml.html", {source => $self->source});
}

sub redirect {
    my ($self) = @_;
    $self->app->redirect($self->source->sso_url);
}

sub assertion {
    my ($self) = @_;

    my ($username, $msg) = $self->source->handle_response($self->app->request->param("SAMLResponse"));

    # We strip the username if the authorization source requires it.
    if(isenabled($self->source->authorization_source->{stripped_user_name})){
        ($username, undef) = strip_username($username);
    }

    if($username){
        $self->username($username);
        $self->done();
    }
    else {
        $self->app->error($msg);
    }
}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2016 Inverse inc.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
USA.

=cut

__PACKAGE__->meta->make_immutable;

1;
