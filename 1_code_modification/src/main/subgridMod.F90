module subgridMod

  !-----------------------------------------------------------------------
  ! !DESCRIPTION:
  ! sub-grid data and mapping types and modules
  !
  ! TODO(wjs, 2015-12-08) Much of the logic here duplicates (in some sense) logic in
  ! initGridCellsMod. The duplication should probably be extracted into routines shared
  ! between these modules (or the two modules should be combined into one).
  !
  ! !USES:
#include "shr_assert.h"
  use shr_kind_mod   , only : r8 => shr_kind_r8
  use spmdMod        , only : masterproc
  use abortutils     , only : endrun
  use clm_varctl     , only : iulog
  use clm_instur     , only : wt_lunit, wt_nat_patch, urban_valid, wt_cft
  use landunit_varcon, only : istcrop, istdlak, istwet, isturb_tbd, isturb_hd, isturb_md
  use glcBehaviorMod , only : glc_behavior_type
  use FatesInterfaceTypesMod, only : fates_maxElementsPerSite
!YS
  use clm_varctl     , only : use_lcz
  use landunit_varcon, only : istcrop, istdlak, istwet
  use landunit_varcon, only : isturb_lcz1, isturb_lcz2, isturb_lcz3, isturb_lcz4, &
                              isturb_lcz5, isturb_lcz6, isturb_lcz7, &
                              isturb_lcz8, isturb_lcz9, isturb_lcz10
!YS                              
  implicit none
  private   
  save

  ! !PUBLIC MEMBER FUNCTIONS:
  public :: subgrid_get_gcellinfo   ! Obtain gridcell properties, summed across all landunits

  ! Routines to get info for each landunit:
  public :: subgrid_get_info_natveg
  public :: natveg_patch_exists ! returns true if the given natural veg patch should be created in memory
  public :: subgrid_get_info_cohort
  public :: subgrid_get_info_urban_tbd
  public :: subgrid_get_info_urban_hd
  public :: subgrid_get_info_urban_md
!YS
  public :: subgrid_get_info_urban_lcz1
  public :: subgrid_get_info_urban_lcz2
  public :: subgrid_get_info_urban_lcz3
  public :: subgrid_get_info_urban_lcz4
  public :: subgrid_get_info_urban_lcz5
  public :: subgrid_get_info_urban_lcz6
  public :: subgrid_get_info_urban_lcz7
  public :: subgrid_get_info_urban_lcz8
  public :: subgrid_get_info_urban_lcz9
  public :: subgrid_get_info_urban_lcz10
!YS    
  public :: subgrid_get_info_lake
  public :: subgrid_get_info_wetland
  public :: subgrid_get_info_glacier_mec
  public :: subgrid_get_info_crop
  public :: crop_patch_exists ! returns true if the given crop patch should be created in memory
  public :: lake_landunit_exists ! returns true if the lake landunit should be created in memory
  public :: urban_landunit_exists ! returns true if the urban landunit should be created in memory
  
  ! !PRIVATE MEMBER FUNCTIONS:
  private :: subgrid_get_info_urban

  character(len=*), parameter, private :: sourcefile = &
       __FILE__
  !-----------------------------------------------------------------------

contains

  !------------------------------------------------------------------------------
  subroutine subgrid_get_gcellinfo (gi, glc_behavior, &
       nlunits, ncols, npatches, ncohorts)
    !
    ! !DESCRIPTION:
    ! Obtain gridcell properties, aggregated across all landunits
    !
    ! !ARGUMENTS
    integer , intent(in)  :: gi       ! grid cell index
    type(glc_behavior_type), intent(in) :: glc_behavior
    integer , intent(out) :: nlunits  ! number of landunits
    integer , intent(out) :: ncols    ! number of columns 
    integer , intent(out) :: npatches ! number of patchs 
    integer , intent(out) :: ncohorts ! number of cohorts 
    !
    ! !LOCAL VARIABLES:
    ! Counts from a single landunit:
    integer :: ncohorts_temp
    integer :: npatches_temp
    integer :: ncols_temp
    integer :: nlunits_temp

    ! atm_topo is arbitrary for the sake of getting these counts. We don't have a true
    ! atm_topo value at the point of this call, so use 0.
    real(r8), parameter :: atm_topo = 0._r8


    !------------------------------------------------------------------------------

    npatches = 0
    ncols    = 0
    nlunits  = 0
    ncohorts = 0

    call subgrid_get_info_natveg(gi, npatches_temp, ncols_temp, nlunits_temp)
    call accumulate_counters()

    ! call this after natveg call because we allocate space for
    ! FATES cohorts based on the number of naturally vegetated columns
    ! and nothing else
    call subgrid_get_info_cohort(gi, ncols_temp, ncohorts)

!YS    call subgrid_get_info_urban_tbd(gi, npatches_temp, ncols_temp, nlunits_temp)
!YS    call accumulate_counters()

!YS    call subgrid_get_info_urban_hd(gi, npatches_temp, ncols_temp, nlunits_temp)
!YS    call accumulate_counters()

!YS    call subgrid_get_info_urban_md(gi, npatches_temp, ncols_temp, nlunits_temp)
!YS    call accumulate_counters()
!YS
    if (.not. use_lcz) then
       call subgrid_get_info_urban_tbd(gi, npatches_temp, ncols_temp, nlunits_temp)
       call accumulate_counters()
       call subgrid_get_info_urban_hd(gi, npatches_temp, ncols_temp, nlunits_temp)
       call accumulate_counters()
       call subgrid_get_info_urban_md(gi, npatches_temp, ncols_temp, nlunits_temp)
       call accumulate_counters()
    else if (use_lcz) then
       call subgrid_get_info_urban_lcz1(gi, npatches_temp, ncols_temp, nlunits_temp)
       call accumulate_counters()
       call subgrid_get_info_urban_lcz2(gi, npatches_temp, ncols_temp, nlunits_temp)
       call accumulate_counters()
       call subgrid_get_info_urban_lcz3(gi, npatches_temp, ncols_temp, nlunits_temp)
       call accumulate_counters()
       call subgrid_get_info_urban_lcz4(gi, npatches_temp, ncols_temp, nlunits_temp)
       call accumulate_counters()
       call subgrid_get_info_urban_lcz5(gi, npatches_temp, ncols_temp, nlunits_temp)
       call accumulate_counters()
       call subgrid_get_info_urban_lcz6(gi, npatches_temp, ncols_temp, nlunits_temp)
       call accumulate_counters()
       call subgrid_get_info_urban_lcz7(gi, npatches_temp, ncols_temp, nlunits_temp)
       call accumulate_counters()
       call subgrid_get_info_urban_lcz8(gi, npatches_temp, ncols_temp, nlunits_temp)
       call accumulate_counters()
       call subgrid_get_info_urban_lcz9(gi, npatches_temp, ncols_temp, nlunits_temp)
       call accumulate_counters()
       call subgrid_get_info_urban_lcz10(gi, npatches_temp, ncols_temp, nlunits_temp)
       call accumulate_counters()
    end if
!YS
    call subgrid_get_info_lake(gi, npatches_temp, ncols_temp, nlunits_temp)
    call accumulate_counters()

    call subgrid_get_info_wetland(gi, npatches_temp, ncols_temp, nlunits_temp)
    call accumulate_counters()

    call subgrid_get_info_glacier_mec(gi, atm_topo, glc_behavior, &
         npatches_temp, ncols_temp, nlunits_temp)
    call accumulate_counters()

    call subgrid_get_info_crop(gi, npatches_temp, ncols_temp, nlunits_temp)
    call accumulate_counters()
   
  contains
    subroutine accumulate_counters
      ! Accumulate running sums of patches, columns and landunits.
      !
      ! This uses local variables in the parent subroutine as both inputs and outputs

      npatches = npatches + npatches_temp
      ncols = ncols + ncols_temp
      nlunits = nlunits + nlunits_temp

    end subroutine accumulate_counters

  end subroutine subgrid_get_gcellinfo

  !-----------------------------------------------------------------------
  subroutine subgrid_get_info_natveg(gi, npatches, ncols, nlunits)
    !
    ! !DESCRIPTION:
    ! Obtain properties for natural vegetated landunit in this grid cell
    !
    ! !USES
    use clm_varpar, only : natpft_lb, natpft_ub
    use clm_instur, only : ncolumns_hillslope
    use clm_varctl, only : use_hillslope
    !
    ! !ARGUMENTS:
    integer, intent(in)  :: gi        ! grid cell index

    integer, intent(out) :: npatches  ! number of nat veg patches in this grid cell
    integer, intent(out) :: ncols     ! number of nat veg columns in this grid cell
    integer, intent(out) :: nlunits   ! number of nat veg landunits in this grid cell
    !
    ! !LOCAL VARIABLES:
    integer :: pft  ! plant functional type index

    character(len=*), parameter :: subname = 'subgrid_get_info_natveg'
    !-----------------------------------------------------------------------

    npatches = 0

    do pft = natpft_lb, natpft_ub
       if (natveg_patch_exists(gi, pft)) then
          npatches = npatches + 1
       end if
    end do

    if (npatches > 0) then
       nlunits = 1
       if (use_hillslope) then
          ! ensure ncols is > 0
          ncols = max(ncolumns_hillslope(gi),1)
       else
          ncols = 1
       endif
       ! Assume that each PFT present in the grid cell is present in every column
       npatches = ncols*npatches

    else
       ! As noted in natveg_patch_exists, we expect a naturally vegetated landunit in
       ! every grid cell. This means that npatches should be at least 1 in every grid
       ! cell. If we find that isn't true, abort.
       write(iulog,*) 'Expect at least one natural veg patch in every grid cell'
       write(iulog,*) 'Found 0 for gi = ', gi
       call endrun(subname//' ERROR: Expect at least one natural veg patch in every grid cell')
    end if

  end subroutine subgrid_get_info_natveg

  !-----------------------------------------------------------------------
  function natveg_patch_exists(gi, pft) result(exists)
    !
    ! !DESCRIPTION:
    ! Returns true if a patch should be created in memory for the given natural veg PFT
    ! in this grid cell.
    !
    ! !USES:
    use clm_varpar, only : natpft_lb, natpft_ub
    use clm_varctl, only : use_cndv, use_fates
    use dynSubgridControlMod, only : get_do_transient_pfts
    !
    ! !ARGUMENTS:
    logical :: exists  ! function result
    integer, intent(in) :: gi  ! grid cell index
    integer, intent(in) :: pft ! plant functional type
    !
    ! !LOCAL VARIABLES:

    character(len=*), parameter :: subname = 'natveg_patch_exists'
    !-----------------------------------------------------------------------

    SHR_ASSERT_FL(pft >= natpft_lb, sourcefile, __LINE__)
    SHR_ASSERT_FL(pft <= natpft_ub, sourcefile, __LINE__)

    if (get_do_transient_pfts() .or. use_cndv .or. use_fates) then
       ! To support transient PFTS and dynamic vegetation cases, we have all possible PFTs
       ! in every grid cell, because they might need to come into existence even if their
       ! weight is 0 at the start of the run. (Similarly for FATES, but there patches do
       ! not correspond to PFTs.)
       exists = .true.

    else
       ! For a non-transient PFT/dynamic-veg run: We still have a naturally vegetated
       ! landunit in every grid cell, because this is needed to support any aspect of
       ! dynamic landunits, as well as to provide forcings for a GLC model. So we don't
       ! take into account the landunit's weight on the gridcell in determining whether to
       ! allocate memory. However, we only allocate memory for patches that actually exist
       ! on this landunit. (This will require running init_interp when changing between a
       ! transient run and a non-transient run.)
       if (wt_nat_patch(gi, pft) > 0.0_r8) then
          exists = .true.
       else
          exists = .false.
       end if
    end if

  end function natveg_patch_exists


  ! -----------------------------------------------------------------------------

  subroutine subgrid_get_info_cohort(gi, ncols, ncohorts)
    !
    ! !DESCRIPTION:
    ! Obtain cohort counts per each gridcell.
    !
    ! !USES
    use clm_varpar, only : natpft_size
    !
    ! !ARGUMENTS:
    integer, intent(in)  :: gi        ! grid cell index
    integer, intent(in)  :: ncols     ! number of nat veg columns in this grid cell
    integer, intent(out) :: ncohorts  ! number of cohorts in this grid cell
    !
    ! !LOCAL VARIABLES:

    character(len=*), parameter :: subname = 'subgrid_get_info_cohort'
    !-----------------------------------------------------------------------

    ! -------------------------------------------------------------------------
    ! Number of cohorts is set here
    ! FATES cohorts populate all natural vegetation columns.
    ! There is only one natural vegetation column per grid-cell.  So allocations
    ! are mapped to the gridcell.  In the future we may have more than one site
    ! per gridcell, and we just multiply that factor here.
    ! It is possible that there may be gridcells that don't have a naturally
    ! vegetated column.  That case should be fine, as the cohort
    ! restart vector will just be a little sparse.
    ! -------------------------------------------------------------------------
    
    ncohorts = ncols*fates_maxElementsPerSite
    
 end subroutine subgrid_get_info_cohort

  !-----------------------------------------------------------------------
  subroutine subgrid_get_info_urban_tbd(gi, npatches, ncols, nlunits)
    !
    ! !DESCRIPTION:
    ! Obtain properties for urban tbd landunit in this grid cell
    !
    ! !ARGUMENTS:
    integer, intent(in)  :: gi        ! grid cell index
    integer, intent(out) :: npatches  ! number of urban tbd patches in this grid cell
    integer, intent(out) :: ncols     ! number of urban tbd columns in this grid cell
    integer, intent(out) :: nlunits   ! number of urban tbd landunits in this grid cell
    !
    ! !LOCAL VARIABLES:

    character(len=*), parameter :: subname = 'subgrid_get_info_urban_tbd'
    !-----------------------------------------------------------------------

    call subgrid_get_info_urban(gi, isturb_tbd, npatches, ncols, nlunits)

  end subroutine subgrid_get_info_urban_tbd

  !-----------------------------------------------------------------------
  subroutine subgrid_get_info_urban_hd(gi, npatches, ncols, nlunits)
    !
    ! !DESCRIPTION:
    ! Obtain properties for urban hd landunit in this grid cell
    !
    ! !ARGUMENTS:
    integer, intent(in)  :: gi        ! grid cell index
    integer, intent(out) :: npatches  ! number of urban hd patches in this grid cell
    integer, intent(out) :: ncols     ! number of urban hd columns in this grid cell
    integer, intent(out) :: nlunits   ! number of urban hd landunits in this grid cell
    !
    ! !LOCAL VARIABLES:

    character(len=*), parameter :: subname = 'subgrid_get_info_urban_hd'
    !-----------------------------------------------------------------------

    call subgrid_get_info_urban(gi, isturb_hd, npatches, ncols, nlunits)

  end subroutine subgrid_get_info_urban_hd

  !-----------------------------------------------------------------------
  subroutine subgrid_get_info_urban_md(gi, npatches, ncols, nlunits)
    !
    ! !DESCRIPTION:
    ! Obtain properties for urban md landunit in this grid cell
    !
    ! !ARGUMENTS:
    integer, intent(in)  :: gi        ! grid cell index
    integer, intent(out) :: npatches  ! number of urban md patches in this grid cell
    integer, intent(out) :: ncols     ! number of urban md columns in this grid cell
    integer, intent(out) :: nlunits   ! number of urban md landunits in this grid cell
    !
    ! !LOCAL VARIABLES:

    character(len=*), parameter :: subname = 'subgrid_get_info_urban_md'
    !-----------------------------------------------------------------------

    call subgrid_get_info_urban(gi, isturb_md, npatches, ncols, nlunits)

  end subroutine subgrid_get_info_urban_md
!YS
  subroutine subgrid_get_info_urban_lcz1(gi, npatches, ncols, nlunits)
    !
    ! !DESCRIPTION:
    ! Obtain properties for urban lcz1 landunit in this grid cell
    !
    ! !ARGUMENTS:
    integer, intent(in)  :: gi        ! grid cell index
    integer, intent(out) :: npatches  ! number of urban lcz1 patches in this grid cell
    integer, intent(out) :: ncols     ! number of urban lcz1 columns in this grid cell
    integer, intent(out) :: nlunits   ! number of urban lcz1 landunits in this grid cell
    !
    ! !LOCAL VARIABLES:

    character(len=*), parameter :: subname = 'subgrid_get_info_urban_lcz1'
    !-----------------------------------------------------------------------

    call subgrid_get_info_urban(gi, isturb_lcz1, npatches, ncols, nlunits)

  end subroutine subgrid_get_info_urban_lcz1

!-----------------------------------------------------------------------
  subroutine subgrid_get_info_urban_lcz2(gi, npatches, ncols, nlunits)
    !
    ! !DESCRIPTION:
    ! Obtain properties for urban lcz2 landunit in this grid cell
    !
    ! !ARGUMENTS:
    integer, intent(in)  :: gi        ! grid cell index
    integer, intent(out) :: npatches  ! number of urban lcz2 patches in this grid cell
    integer, intent(out) :: ncols     ! number of urban lcz2 columns in this grid cell
    integer, intent(out) :: nlunits   ! number of urban lcz2 landunits in this grid cell
    !
    ! !LOCAL VARIABLES:

    character(len=*), parameter :: subname = 'subgrid_get_info_urban_lcz2'
    !-----------------------------------------------------------------------

    call subgrid_get_info_urban(gi, isturb_lcz2, npatches, ncols, nlunits)

  end subroutine subgrid_get_info_urban_lcz2  

!-----------------------------------------------------------------------
  subroutine subgrid_get_info_urban_lcz3(gi, npatches, ncols, nlunits)
    !
    ! !DESCRIPTION:
    ! Obtain properties for urban lcz3 landunit in this grid cell
    !
    ! !ARGUMENTS:
    integer, intent(in)  :: gi        ! grid cell index
    integer, intent(out) :: npatches  ! number of urban lcz3 patches in this grid cell
    integer, intent(out) :: ncols     ! number of urban lcz3 columns in this grid cell
    integer, intent(out) :: nlunits   ! number of urban lcz3 landunits in this grid cell
    !
    ! !LOCAL VARIABLES:

    character(len=*), parameter :: subname = 'subgrid_get_info_urban_lcz3'
    !-----------------------------------------------------------------------

    call subgrid_get_info_urban(gi, isturb_lcz3, npatches, ncols, nlunits)

  end subroutine subgrid_get_info_urban_lcz3  

!-----------------------------------------------------------------------
  subroutine subgrid_get_info_urban_lcz4(gi, npatches, ncols, nlunits)
    !
    ! !DESCRIPTION:
    ! Obtain properties for urban lcz4 landunit in this grid cell
    !
    ! !ARGUMENTS:
    integer, intent(in)  :: gi        ! grid cell index
    integer, intent(out) :: npatches  ! number of urban lcz4 patches in this grid cell
    integer, intent(out) :: ncols     ! number of urban lcz4 columns in this grid cell
    integer, intent(out) :: nlunits   ! number of urban lcz4 landunits in this grid cell
    !
    ! !LOCAL VARIABLES:

    character(len=*), parameter :: subname = 'subgrid_get_info_urban_lcz4'
    !-----------------------------------------------------------------------

    call subgrid_get_info_urban(gi, isturb_lcz4, npatches, ncols, nlunits)

  end subroutine subgrid_get_info_urban_lcz4  

!-----------------------------------------------------------------------
  subroutine subgrid_get_info_urban_lcz5(gi, npatches, ncols, nlunits)
    !
    ! !DESCRIPTION:
    ! Obtain properties for urban lcz5 landunit in this grid cell
    !
    ! !ARGUMENTS:
    integer, intent(in)  :: gi        ! grid cell index
    integer, intent(out) :: npatches  ! number of urban lcz5 patches in this grid cell
    integer, intent(out) :: ncols     ! number of urban lcz5 columns in this grid cell
    integer, intent(out) :: nlunits   ! number of urban lcz5 landunits in this grid cell
    !
    ! !LOCAL VARIABLES:

    character(len=*), parameter :: subname = 'subgrid_get_info_urban_lcz5'
    !-----------------------------------------------------------------------

    call subgrid_get_info_urban(gi, isturb_lcz5, npatches, ncols, nlunits)

  end subroutine subgrid_get_info_urban_lcz5  

!-----------------------------------------------------------------------
  subroutine subgrid_get_info_urban_lcz6(gi, npatches, ncols, nlunits)
    !
    ! !DESCRIPTION:
    ! Obtain properties for urban lcz6 landunit in this grid cell
    !
    ! !ARGUMENTS:
    integer, intent(in)  :: gi        ! grid cell index
    integer, intent(out) :: npatches  ! number of urban lcz6 patches in this grid cell
    integer, intent(out) :: ncols     ! number of urban lcz6 columns in this grid cell
    integer, intent(out) :: nlunits   ! number of urban lcz6 landunits in this grid cell
    !
    ! !LOCAL VARIABLES:

    character(len=*), parameter :: subname = 'subgrid_get_info_urban_lcz6'
    !-----------------------------------------------------------------------

    call subgrid_get_info_urban(gi, isturb_lcz6, npatches, ncols, nlunits)

  end subroutine subgrid_get_info_urban_lcz6

!-----------------------------------------------------------------------
  subroutine subgrid_get_info_urban_lcz7(gi, npatches, ncols, nlunits)
    !
    ! !DESCRIPTION:
    ! Obtain properties for urban lcz7 landunit in this grid cell
    !
    ! !ARGUMENTS:
    integer, intent(in)  :: gi        ! grid cell index
    integer, intent(out) :: npatches  ! number of urban lcz7 patches in this grid cell
    integer, intent(out) :: ncols     ! number of urban lcz7 columns in this grid cell
    integer, intent(out) :: nlunits   ! number of urban lcz7 landunits in this grid cell
    !
    ! !LOCAL VARIABLES:

    character(len=*), parameter :: subname = 'subgrid_get_info_urban_lcz7'
    !-----------------------------------------------------------------------

    call subgrid_get_info_urban(gi, isturb_lcz7, npatches, ncols, nlunits)

  end subroutine subgrid_get_info_urban_lcz7  

!-----------------------------------------------------------------------
  subroutine subgrid_get_info_urban_lcz8(gi, npatches, ncols, nlunits)
    !
    ! !DESCRIPTION:
    ! Obtain properties for urban lcz8 landunit in this grid cell
    !
    ! !ARGUMENTS:
    integer, intent(in)  :: gi        ! grid cell index
    integer, intent(out) :: npatches  ! number of urban lcz8 patches in this grid cell
    integer, intent(out) :: ncols     ! number of urban lcz8 columns in this grid cell
    integer, intent(out) :: nlunits   ! number of urban lcz8 landunits in this grid cell
    !
    ! !LOCAL VARIABLES:

    character(len=*), parameter :: subname = 'subgrid_get_info_urban_lcz8'
    !-----------------------------------------------------------------------

    call subgrid_get_info_urban(gi, isturb_lcz8, npatches, ncols, nlunits)

  end subroutine subgrid_get_info_urban_lcz8  

!-----------------------------------------------------------------------
  subroutine subgrid_get_info_urban_lcz9(gi, npatches, ncols, nlunits)
    !
    ! !DESCRIPTION:
    ! Obtain properties for urban lcz9 landunit in this grid cell
    !
    ! !ARGUMENTS:
    integer, intent(in)  :: gi        ! grid cell index
    integer, intent(out) :: npatches  ! number of urban lcz9 patches in this grid cell
    integer, intent(out) :: ncols     ! number of urban lcz9 columns in this grid cell
    integer, intent(out) :: nlunits   ! number of urban lcz9 landunits in this grid cell
    !
    ! !LOCAL VARIABLES:

    character(len=*), parameter :: subname = 'subgrid_get_info_urban_lcz9'
    !-----------------------------------------------------------------------

    call subgrid_get_info_urban(gi, isturb_lcz9, npatches, ncols, nlunits)

  end subroutine subgrid_get_info_urban_lcz9  

!-----------------------------------------------------------------------
  subroutine subgrid_get_info_urban_lcz10(gi, npatches, ncols, nlunits)
    !
    ! !DESCRIPTION:
    ! Obtain properties for urban lcz10 landunit in this grid cell
    !
    ! !ARGUMENTS:
    integer, intent(in)  :: gi        ! grid cell index
    integer, intent(out) :: npatches  ! number of urban lcz10 patches in this grid cell
    integer, intent(out) :: ncols     ! number of urban lcz10 columns in this grid cell
    integer, intent(out) :: nlunits   ! number of urban lcz10 landunits in this grid cell
    !
    ! !LOCAL VARIABLES:

    character(len=*), parameter :: subname = 'subgrid_get_info_urban_lcz10'
    !-----------------------------------------------------------------------

    call subgrid_get_info_urban(gi, isturb_lcz10, npatches, ncols, nlunits)

  end subroutine subgrid_get_info_urban_lcz10 
!YS
  !-----------------------------------------------------------------------
  subroutine subgrid_get_info_urban(gi, ltype, npatches, ncols, nlunits)
    !
    ! !DESCRIPTION:
    ! Obtain properties for one of the urban landunits in this grid cell
    !
    ! This is shared for all urban landunits, because currently they are all treated the same.
    !
    ! !USES
    use clm_varpar, only : maxpatch_urb
    use clm_varctl, only : run_zero_weight_urban
    !
    ! !ARGUMENTS:
    integer, intent(in)  :: gi        ! grid cell index
    integer, intent(in)  :: ltype     ! landunit type (isturb_tbd, etc.)
    integer, intent(out) :: npatches  ! number of urban patches in this grid cell, for one urban landunit
    integer, intent(out) :: ncols     ! number of urban columns in this grid cell, for one urban landunit
    integer, intent(out) :: nlunits   ! number of urban landunits in this grid cell, for one urban landunit
    !
    ! !LOCAL VARIABLES:
    logical :: this_landunit_exists

    character(len=*), parameter :: subname = 'subgrid_get_info_urban'
    !-----------------------------------------------------------------------

    ! In general, only allocate memory for urban landunits that have non-zero weight.
    !
    ! However, if run_zero_weight_urban is .true., then allocate memory for all urban landunits in
    ! every grid cell that has valid urban parameters. (This is useful if you want to
    ! know urban behavior for all potential urban areas, or - in the future - to support
    ! transient urban areas via dynamic landunits.)
    !
    ! In either case, for simplicity, we always allocate space for all columns on any
    ! allocated urban landunits.
    
    ! For dynamic urban: to improve efficiency, 'PCT_URBAN_MAX' is added in landuse.timeseries
    ! that tells if any urban landunit ever grows in a given grid cell in a transient
    ! run. The urban landunit is allocated only if PCT_URBAN_MAX is greater than 0. (#1572)

    if (run_zero_weight_urban) then
       if (urban_valid(gi)) then
          this_landunit_exists = .true.
       else
          this_landunit_exists = .false.
       end if
    else
      if (urban_landunit_exists(gi, ltype)) then
         this_landunit_exists = .true.
      else
         this_landunit_exists = .false.
      end if
    end if

    if (this_landunit_exists) then
       npatches = maxpatch_urb
       ncols = npatches
       nlunits = 1
    else
       npatches = 0
       ncols = 0
       nlunits = 0
    end if


  end subroutine subgrid_get_info_urban

  !-----------------------------------------------------------------------
  subroutine subgrid_get_info_lake(gi, npatches, ncols, nlunits)
    !
    ! !DESCRIPTION:
    ! Obtain properties for lake landunit in this grid cell
    !
    ! !ARGUMENTS:
    integer, intent(in)  :: gi        ! grid cell index
    integer, intent(out) :: npatches  ! number of lake patches in this grid cell
    integer, intent(out) :: ncols     ! number of lake columns in this grid cell
    integer, intent(out) :: nlunits   ! number of lake landunits in this grid cell
    !
    ! !LOCAL VARIABLES:

    character(len=*), parameter :: subname = 'subgrid_get_info_lake'
    !-----------------------------------------------------------------------

    ! We do allow the lake landunit to expand via dynamic landunits, so we
    !  need to allocate space for where it is known that the lake unit will grow.
    
    if (lake_landunit_exists(gi) ) then
       npatches = 1
       ncols = 1
       nlunits = 1
    else
       npatches = 0
       ncols = 0
       nlunits = 0
    end if

  end subroutine subgrid_get_info_lake

  !-----------------------------------------------------------------------
  subroutine subgrid_get_info_wetland(gi, npatches, ncols, nlunits)
    !
    ! !DESCRIPTION:
    ! Obtain properties for wetland landunit in this grid cell
    !
    ! !ARGUMENTS:
    integer, intent(in)  :: gi        ! grid cell index
    integer, intent(out) :: npatches  ! number of wetland patches in this grid cell
    integer, intent(out) :: ncols     ! number of wetland columns in this grid cell
    integer, intent(out) :: nlunits   ! number of wetland landunits in this grid cell
    !
    ! !LOCAL VARIABLES:

    character(len=*), parameter :: subname = 'subgrid_get_info_wetland'
    !-----------------------------------------------------------------------

    ! We currently do NOT allow the wetland landunit to expand via dynamic landunits, so we
    ! only need to allocate space for it where its weight is currently non-zero.

    if (wt_lunit(gi, istwet) > 0.0_r8) then
       npatches = 1
       ncols = 1
       nlunits = 1
    else
       npatches = 0
       ncols = 0
       nlunits = 0
    end if

  end subroutine subgrid_get_info_wetland
  
  !-----------------------------------------------------------------------
  subroutine subgrid_get_info_glacier_mec(gi, atm_topo, glc_behavior, npatches, ncols, nlunits)
    !
    ! !DESCRIPTION:
    ! Obtain properties for glacier_mec landunit in this grid cell
    !
    ! !ARGUMENTS:
    integer, intent(in)  :: gi        ! grid cell index
    real(r8), intent(in) :: atm_topo  ! atmosphere's topographic height for this grid cell (m)
    type(glc_behavior_type), intent(in) :: glc_behavior
    integer, intent(out) :: npatches  ! number of glacier_mec patches in this grid cell
    integer, intent(out) :: ncols     ! number of glacier_mec columns in this grid cell
    integer, intent(out) :: nlunits   ! number of glacier_mec landunits in this grid cell
    !
    ! !LOCAL VARIABLES:

    character(len=*), parameter :: subname = 'subgrid_get_info_glacier_mec'
    !-----------------------------------------------------------------------

    call glc_behavior%get_num_glc_subgrid(gi, atm_topo, npatches, ncols, nlunits)

  end subroutine subgrid_get_info_glacier_mec

  !-----------------------------------------------------------------------
  subroutine subgrid_get_info_crop(gi, npatches, ncols, nlunits)
    !
    ! !DESCRIPTION:
    ! Obtain properties for crop landunit in this grid cell
    !
    ! !USES:
    use clm_varpar, only : cft_lb, cft_ub
    !
    ! !ARGUMENTS:
    integer, intent(in)  :: gi        ! grid cell index
    integer, intent(out) :: npatches  ! number of nat veg patches in this grid cell
    integer, intent(out) :: ncols     ! number of nat veg columns in this grid cell
    integer, intent(out) :: nlunits   ! number of nat veg landunits in this grid cell
    !
    ! !LOCAL VARIABLES:
    integer :: cft  ! crop functional type index

    character(len=*), parameter :: subname = 'subgrid_get_info_crop'
    !-----------------------------------------------------------------------

    npatches = 0
    do cft = cft_lb, cft_ub
       if (crop_patch_exists(gi, cft)) then
          npatches = npatches + 1
       end if
    end do

    if (npatches > 0) then
       ncols = npatches
       nlunits = 1
    else
       ncols = 0
       nlunits = 0
    end if

  end subroutine subgrid_get_info_crop

  !-----------------------------------------------------------------------
  function crop_patch_exists(gi, cft) result(exists)
    !
    ! !DESCRIPTION:
    ! Returns true if a patch should be created in memory for the given crop functional
    ! type in this grid cell.
    !
    ! This just applies to the crop landunit: it always returns .false. if
    ! create_crop_landunit is .false.
    !
    ! !USES:
    use clm_varpar           , only : cft_lb, cft_ub
    use clm_varctl           , only : create_crop_landunit
    use pftconmod            , only : pftcon
    use dynSubgridControlMod , only : get_do_transient_crops
    !
    ! !ARGUMENTS:
    logical :: exists  ! function result
    integer, intent(in) :: gi  ! grid cell index
    integer, intent(in) :: cft ! crop functional type
    !
    ! !LOCAL VARIABLES:

    character(len=*), parameter :: subname = 'crop_patch_exists'
    !-----------------------------------------------------------------------

    if (create_crop_landunit) then
       SHR_ASSERT_FL(cft >= cft_lb, sourcefile, __LINE__)
       SHR_ASSERT_FL(cft <= cft_ub, sourcefile, __LINE__)

       if (get_do_transient_crops()) then
          ! To support dynamic landunits, we have all possible crop columns in every grid
          ! cell, because they might need to come into existence even if their weight is 0 at
          ! the start of the run.
          if (pftcon%is_pft_known_to_model(cft)) then
             exists = .true.
          else
             exists = .false.
          end if

       else
          ! For a run without transient crops, only allocate memory for crops that are
          ! actually present in this run. (This will require running init_interp when
          ! changing between a transient crop run and a non-transient run.)
          if (wt_lunit(gi, istcrop) > 0.0_r8 .and. wt_cft(gi, cft) > 0.0_r8) then
             exists = .true.
          else
             exists = .false.
          end if
       end if

    else  ! create_crop_landunit false
       exists = .false.
    end if

  end function crop_patch_exists

!-----------------------------------------------------------------------
  function lake_landunit_exists(gi) result(exists)
    !
    ! !DESCRIPTION:
    ! Returns true if a land unit for lakes should be created in memory
    ! which is defined for gridcells which will grow lake, given by pct_lake_max
    ! 
    ! !USES:
    use dynSubgridControlMod , only : get_do_transient_lakes
    use clm_instur           , only : pct_lake_max
    !
    ! !ARGUMENTS:
    logical :: exists  ! function result
    integer, intent(in) :: gi  ! grid cell index
    !
    ! !LOCAL VARIABLES:

    character(len=*), parameter :: subname = 'lake_landunit_exists'
    !-----------------------------------------------------------------------

    if (get_do_transient_lakes()) then
       ! To support dynamic landunits, we initialise a lake land unit in
       ! each grid cell in which there are lakes as defined by pct_lake_max
       
       if (pct_lake_max(gi) > 0._r8) then
            exists = .true.
       else
            exists = .false.
       end if
        
    else 
        ! For a run without transient lakes, only allocate memory for lakes actually present in run)
        if (wt_lunit(gi, istdlak) > 0.0_r8) then
            exists = .true.
        else
            exists = .false.
        end if
    end if

  end function lake_landunit_exists

!-----------------------------------------------------------------------
  function urban_landunit_exists(gi, ltype) result(exists)
    !
    ! !DESCRIPTION:
    ! Returns true if a landunit for urban should be created in memory
    ! which is defined for gridcells which will grow urban, given by pct_urban_max
    ! 
    ! !USES:
    use dynSubgridControlMod , only : get_do_transient_urban
    use clm_instur           , only : pct_urban_max
    use landunit_varcon      , only : isturb_MIN
    !
    ! !ARGUMENTS:
    logical :: exists  ! function result
    integer, intent(in) :: gi  ! grid cell index
    integer, intent(in) :: ltype   !landunit type (isturb_tbd, etc.)
    !
    ! !LOCAL VARIABLES:
    integer :: dens_index ! urban density type index

    character(len=*), parameter :: subname = 'urban_landunit_exists'
    !-----------------------------------------------------------------------

    if (get_do_transient_urban()) then
       ! To support dynamic landunits, we initialize an urban land unit in each grid cell 
       ! in which there are urban. This is defined by the pct_urban_max variable.
       
       dens_index = ltype - isturb_MIN + 1
       if (pct_urban_max(gi,dens_index) > 0.0_r8) then
            exists = .true.
       else
            exists = .false.
       end if
        
    else 
        ! For a run without transient urban, only allocate memory for urban land units
        ! actually present in run.
        if (wt_lunit(gi, ltype) > 0.0_r8) then
            exists = .true.
        else
            exists = .false.
        end if
    end if

  end function urban_landunit_exists
    
end module subgridMod
